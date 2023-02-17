#!/usr/bin/env python
"""

Copyright 2020, The Regents of the University of California.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE REGENTS OF THE UNIVERSITY OF CALIFORNIA ''AS
IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OF THE UNIVERSITY OF CALIFORNIA OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of The Regents of the University of California.

"""

import itertools
import logging
import os
import random
import string
from textwrap import wrap
#Quality of life import
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

#Provides standard python unit testing capabilities for cocotb. Source: https://pypi.org/project/cocotb-test/
import cocotb_test.simulator

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.regression import TestFactory
from cocotb.binary import BinaryValue
from cocotb.result import TestError, TestSuccess, TestFailure

from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink, AxiStreamMonitor
import sys
sys.path.insert(0, "..")
from BitMonitor import BitMonitor
from AxiStreamClockedMonitor import AxiStreamClockedMonitor
from ChaCha20_Poly1305_enc_dec import our_encryptor, our_decryptor

class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.start_soon(Clock(dut.clk, 4, units='ps').start())
        self.__next_is_sop__ = False

        # connect TB source to DUT sink, and vice versa
        self.source  = AxiStreamSource (AxiStreamBus.from_prefix(dut, "sink"), dut.clk, dut.rst, byte_lanes = 16)
        self.sink    =   AxiStreamSink (AxiStreamBus.from_prefix(dut, "source" ), dut.clk, dut.rst, byte_lanes = 16)
        
        #This monitor is instantiated "from the INPUT side". Thus it effectively only has signals relevant to the INPUT.
        #self.monitor = AxiStreamMonitor(AxiStreamBus.from_prefix(dut, "source" ), dut.clk, dut.rst)
        
        #Instantiate the signal sniffers through the use of BitMonitor class or bus sniffers with the use of AxiStreamClockedMonitor class
        #self.source_bus_tlast_monitor = BitMonitor("source_bus_tlast", self.source.bus.tlast, self.dut.clk, True, callback=self.model)
        #self.in_out_bus_monitor = AxiStreamClockedMonitor("sink_source_bus", self.monitor, self.dut.clk, True, callback=self.callback_function, event=None)

    def is_start_of_packet(self, transaction_info):
        if(transaction_info['tvalid'] == '1' and transaction_info['tready'] == '1'):
            self.__next_is_sop__ = transaction_info['tlast']
        if(transaction_info['tvalid'] == '1' and transaction_info['tready'] == '1' and self.__next_is_sop__):
            #Reset state of __next_is_sop__ flag for next set of transactions
            self.__next_is_sop__ = False
            return True
        return False

    def callback_function(self, transaction_info):
        #This is the clock-level test
        print(transaction_info)
        if(self.is_start_of_packet(transaction_info)):
            #This branch is the test of Start Of Packet.
            print("START OF PACKET")

    def set_idle_generator(self, generator=None):
        if generator:
            self.source.set_pause_generator(generator())

    async def reset(self):
        self.dut.rst.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.rst.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)

    async def check_for_liveliness(self):
        clock_counter = 0
        chacha_packets = 0
        chacha_timeout = 0
        while(True):
            await RisingEdge(self.dut.clk)
            # packet to ChaCha?
            if (self.source.bus.tvalid.value & self.source.bus.tlast.value):
                chacha_packets += 1
                self.log.info("%d packets in-flight" % chacha_packets)
                chacha_timeout = 0
            clock_counter += 1
            if (chacha_packets > 0):
                chacha_timeout += 1
            # packet from ChaCha?
            if (self.sink.bus.tvalid.value & self.sink.bus.tlast.value):
                chacha_packets -= 1
                self.log.info("%d packets in-flight" % chacha_packets)
                print("TAG_VALID = %d" % self.dut.tag_valid.value)
                await RisingEdge(self.dut.clk)
                print("TAG_VALID = %d" % self.dut.tag_valid.value)
                await RisingEdge(self.dut.clk)
                print("TAG_VALID = %d" % self.dut.tag_valid.value)
                if (chacha_packets):
                    chacha_timeout = 0

            assert(chacha_timeout < 1500)


async def run_test(dut, payload_data=None, idle_inserter=None):
    '''
    tb = TB(dut)
    
    await tb.reset()    
    tb.set_idle_generator(idle_inserter)
    payload_dict    = payload_data()
    payload         = payload_dict["ciphertext"]
    printout        = ''.join(' {:02x}'.format(x) for x in payload)
    printout        = wrap(printout, 48)
    plaintext       = payload_dict["plaintext"]

    key             = payload_dict["key"]
    data_valid      = payload_dict["data_valid"]
    tb.dut.in_key   = BinaryValue(value=key, n_bits=len(key) * 8)


    test_frame      = AxiStreamFrame(payload)
    assert len(key) == 32

    await tb.source.send(test_frame)
    
    try:
        cocotb.start_soon(tb.check_for_liveliness())
    except TimeoutError:
        print("The DUT has timed out. If this is an expected behavior, the test is considered a success")
        if(data_valid):
            raise TestFailure("Expected test to finish, but the DUT has hanged when given propper data.")
        else:
            pass

    rx_frame        = await tb.sink.recv()
    rx_frame        = reverse_bytearray(rx_frame.tdata)
    
    assert rx_frame == plaintext

    for i in range(10):
        await RisingEdge(tb.dut.clk)
    '''
    pass

def cycle_pause():
    return itertools.cycle([0])

def reverse_bytearray(byte_array):
    info = [byte_array[i : i + 16] for i in range(0, len(byte_array), 16)]

    for i in range(0, len(info)):
        info[i].reverse()

    return bytearray(b''.join(info))



def test_case_1():
    
    #Default test without using our_encryptor/our_decryptor, parameters of test agreed upon by the team internally. 
    key = '80 81 82 83 84 85 86 87 88 89 8a 8b 8c 8d 8e 8f 90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F '
    plaintext = b'Ladies and Gentlemen of the class of \'99: If I could offer you only one tip for the future, sunscreen would be it.\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    key = bytes(bytearray.fromhex(key))
    aad = ''#'50 51 52 53 c0 c1 c2 c3 c4 c5 c6 c7'
    aad = bytearray.fromhex(aad)
    ciphertext_hex = '04 00 00 80 00 00 00 01 40 41 42 43 44 45 46 47 '
    ciphertext_hex+= 'a4 79 cb 54 62 89 46 d6 f4 04 2a 8e 38 4e f4 bd ' 
    ciphertext_hex+= '2f bc 73 30 b8 be 55 eb 2d 8d c1 8a aa 51 d6 6a ' 
    ciphertext_hex+= '8e c1 f8 d3 61 9a 25 8d b0 ac 56 95 60 15 b7 b4 ' 
    ciphertext_hex+= '93 7e 9b 8e 6a a9 57 b3 dc 02 14 d8 03 d7 76 60 ' 
    ciphertext_hex+= 'aa bc 91 30 92 97 1d a8 f2 07 17 1c e7 84 36 08 ' 
    ciphertext_hex+= '16 2e 2e 75 9d 8e fc 25 d8 d0 93 69 90 af 63 c8 ' 
    ciphertext_hex+= '20 ba 87 e8 a9 55 b5 c8 27 4e f7 d1 0f 6f af d0 ' 
    ciphertext_hex+= '46 47 1b 14 57 76 ac a2 f7 cf 6a 61 d2 16 64 25 ' 
    ciphertext_hex+= '2f b1 f5 ba d2 ee 98 e9 64 8b b1 7f 43 2d cc e4 '
    ciphertext_hex = bytearray.fromhex(ciphertext_hex)
    
    plaintext_hex = our_decryptor(key, ciphertext_hex[8:16], ciphertext_hex[16:], aad)
    ciphertext_hex = reverse_bytearray(ciphertext_hex)
    
    return {"ciphertext": ciphertext_hex, "key": key, "data_valid": True, "plaintext" :  plaintext}
    
def test_case_2():

    #Same as test1, this time we're using our_encryptor and validating if we're decrypting the ciphertext correctly.
    key            = '80 81 82 83 84 85 86 87 88 89 8a 8b 8c 8d 8e 8f 90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F '
    header_counter = '04 00 00 80 00 00 00 01 40 41 42 43 44 45 46 47 '
    aad            = ''
    key            = bytes(bytearray.fromhex(key))
    header_counter = bytearray.fromhex(header_counter)
    aad            = bytearray.fromhex(aad)
    plaintext      = b'Ladies and Gentlemen of the class of \'99: If I could offer you only one tip for the future, sunscreen would be it.\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

    try:
        ciphertext_hex, digest = our_encryptor(key, header_counter[8:], plaintext, aad)
        ciphertext_hex = header_counter + ciphertext_hex + digest
        ciphertext_hex = reverse_bytearray(ciphertext_hex)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": False, "plaintext": plaintext}
    except:
        return {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        
def test_case_3():

    #Zero key and zero-nonce test
    key            = '00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 '
    header_counter = '04 00 00 80 00 00 00 01 00 00 00 00 00 00 00 00 '
    aad            = ''
    key            = bytes(bytearray.fromhex(key))
    header_counter = bytearray.fromhex(header_counter)
    aad            = bytearray.fromhex(aad)
    plaintext      = b'Ladies and Gentlemen of the class of \'99: If I could offer you only one tip for the future, sunscreen would be it.\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

    try:
        ciphertext_hex, digest = our_encryptor(key, header_counter[8:], plaintext, aad)
        ciphertext_hex = header_counter + ciphertext_hex + digest
        ciphertext_hex = reverse_bytearray(ciphertext_hex)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": True, "plaintext": plaintext}

    except:
        retval = {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        return retval

def test_case_4():

    #Empty text test, zero key + zero nonce test
    #Zero key and zero-nonce test
    key            = '00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 '
    header_counter = '04 00 00 80 00 00 00 01 00 00 00 00 00 00 00 00 '
    aad            = ''
    key            = bytes(bytearray.fromhex(key))
    header_counter = bytearray.fromhex(header_counter)
    aad            = bytearray.fromhex(aad)
    plaintext      = b'\x00'*160


    try:
        ciphertext_hex, digest = our_encryptor(key, header_counter[8:], plaintext, aad)
        ciphertext_hex = header_counter + ciphertext_hex + digest
        ciphertext_hex = reverse_bytearray(ciphertext_hex)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": False, "plaintext": plaintext}
        
    except:
        return {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        
def test_case_5():
    
    #None test, should fail
    key            = ''#'00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 '
    header_counter = ''#'04 00 00 80 00 00 00 01 00 00 00 00 00 00 00 00 '
    aad            = ''
    key            = bytes(bytearray.fromhex(key))
    header_counter = bytearray.fromhex(header_counter)
    aad            = bytearray.fromhex(aad)
    plaintext      = b''

    try:
        ciphertext_hex, digest = our_encryptor(key, header_counter[8:], plaintext, aad)
        ciphertext_hex = header_counter + ciphertext_hex + digest
        ciphertext_hex = reverse_bytearray(ciphertext_hex)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": False, "plaintext": plaintext}

    except:
        return {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}

def test_case_6():

    #Large ammount of data test   
    key               = '00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 '
    header_counter    = '04 00 00 00 00 00 00 01 00 00 00 00 00 00 00 00 '
    aad               = ''
    key               = bytes(bytearray.fromhex(key))
    aad               = bytearray.fromhex(aad)
    plaintext_length  = random.randint(1, 1504)
    plaintext         = bytearray(bytes(''.join(random.choice(string.ascii_letters + string.punctuation + string.whitespace + string.digits) for i in range(plaintext_length)), 'utf-8'))
    
    

    assert len(plaintext) == plaintext_length
    while len(plaintext) % 16 != 0:
        plaintext.append(0)

    hex_number        = int(len(plaintext) /16)
    hex_number        = format(hex_number, 'x')

    if(len(hex_number) < 2):
        hex_number = '0' + hex_number
    
    if(len(hex_number) > 2):
        header_counter = header_counter[0:7] + hex_number[0] + ' ' + hex_number[1:] + header_counter[11:]
    else:
        header_counter = header_counter[0:7] + hex_number[0] + ' ' + hex_number[1] + '0' + header_counter[11:]

    header_counter     = bytearray.fromhex(header_counter)

    try:
        ciphertext_hex, digest = our_encryptor(key, header_counter[8:], plaintext, aad)
        ciphertext_hex = header_counter + ciphertext_hex + digest
        ciphertext_hex = reverse_bytearray(ciphertext_hex)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": True, "plaintext": plaintext}

    except:
        retval = {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        return retval

if cocotb.SIM_NAME:    
    factory = TestFactory(run_test)
    factory.add_option("payload_data",  [None])#test_case_6, test_case_6, test_case_6, test_case_6, test_case_6, test_case_6, test_case_1, test_case_2, test_case_3, test_case_4, test_case_5])
    factory.add_option("idle_inserter", [None])#, cycle_pause])
    factory.generate_tests()

tests_dir = os.path.dirname(__file__)
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..'))

def test_AEAD_encryption_wrapper(request):
    dut = "AEAD_encryption_wrapper"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.vhd"),
    ]

    parameters = {}
    extra_env = {}
    sim_build = os.path.join(tests_dir, "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search=[tests_dir],       # list of aditional directories to search for python/cocotb modules
        verilog_sources=verilog_sources, # sources for testing
        toplevel=toplevel,               # name of the top level HDL
        module=module,                   # name of the cocotb test module, in this case test_AEAD_decryption_wrapper.py
        parameters=parameters,           # a dictionary of top-level parameters/generics
        sim_build=sim_build,             # the directory used to compile the tests
        extra_env=extra_env,             # a dictionary of extra environment variables set in simulator proces
    )
