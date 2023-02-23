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
import re
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

    async def check_for_liveliness(self, packet_length):
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
            # is sink ready ?
            if 'U' in self.sink.bus.tvalid.value.binstr or 'U' in self.sink.bus.tlast.value.binstr:
                #print("SINK NOT READY")
                chacha_timeout += 1
            elif 'X' in self.sink.bus.tvalid.value.binstr or 'X' in self.sink.bus.tlast.value.binstr:
                chacha_timeout += 1
            else:
                # packet from ChaCha?
                if (self.sink.bus.tvalid.value & self.sink.bus.tlast.value):
                    chacha_packets -= 1
                    self.log.info("%d packets in-flight" % chacha_packets)
                    #print("TAG_VALID = %d" % self.dut.tag_valid.value)
                    await RisingEdge(self.dut.clk)
                    #print("TAG_VALID = %d" % self.dut.tag_valid.value)
                    await RisingEdge(self.dut.clk)
                    #print("TAG_VALID = %d" % self.dut.tag_valid.value)
                    if (chacha_packets):
                        chacha_timeout = 0
                        
            assert(chacha_timeout < packet_length * 10)


async def run_test(dut, payload_data=None, idle_inserter=None):
    
    tb = TB(dut)
    
    await tb.reset()   

    for i in range(20):
        await RisingEdge(tb.dut.clk)

    tb.set_idle_generator(idle_inserter)
    
    payload_dict    = payload_data()
    payload         = payload_dict["plaintext"]
    ciphertext      = payload_dict["ciphertext"]

    key             = payload_dict["key"]
    data_valid      = payload_dict["data_valid"]
    tb.dut.in_key   = BinaryValue(value=key, n_bits=len(key) * 8)

    
    test_frame      = AxiStreamFrame(payload)
    assert len(key) == 32
    
    await tb.source.send(test_frame)
    
    try:
        coro        = cocotb.start_soon(tb.check_for_liveliness(len(payload)))
        print("Started liveliness test")
        rx_frame    = await tb.sink.recv()
        assert rx_frame.tdata == ciphertext[16:]
    except:
        print("The DUT has timed out. If this is an expected behavior, the test is considered a success")
        rx_frame    = b''
        if(data_valid):
            raise TestFailure("Expected test to finish, but the DUT has hanged when given propper data.")
        else:
            pass
    coro.cancel()
    for i in range(20):
        await RisingEdge(tb.dut.clk)
    
    pass

def cycle_pause():
    return itertools.cycle([0])

def reverse_bytearray(byte_array):
    info = [byte_array[i : i + 16] for i in range(0, len(byte_array), 16)]

    for i in range(0, len(info)):
        info[i].reverse()

    return bytearray(b''.join(info))


hex_chars = "0123456789abcdef"
seed      = 0

def replace(match):
    global seed
    index = match.start()
    random.seed(seed + index)
    return ''.join([random.choice(hex_chars) for _ in range(2)])


def test_case_1():

    #Same as test1, this time we're using our_encryptor and validating if we're decrypting the ciphertext correctly.
    key            = '00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f '
    header_counter = '04 00 00 80 00 00 00 01 00 00 00 00 00 00 00 00 '
    aad            = ''
    key            = bytes(bytearray.fromhex(key))
    header_counter = bytearray.fromhex(header_counter)
    aad            = bytearray.fromhex(aad)
    plaintext      = b'Ladies and Gentlemen of the class of \'99: If I could offer you only one tip for the future, sunscreen would be it.\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

    try:
        ciphertext_hex, digest = our_encryptor(key, header_counter[8:], plaintext, aad)
        ciphertext_hex         = header_counter + ciphertext_hex + digest
        ciphertext_hex         = reverse_bytearray(ciphertext_hex)

        plaintext              = header_counter + plaintext
        plaintext              = reverse_bytearray(plaintext)

        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": True, "plaintext": plaintext}
    except:
        return {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        
def test_case_2():

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
        ciphertext_hex         = header_counter + ciphertext_hex + digest
        ciphertext_hex         = reverse_bytearray(ciphertext_hex)

        plaintext              = header_counter + plaintext
        plaintext              = reverse_bytearray(plaintext)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": True, "plaintext": plaintext}

    except:
        retval = {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        return retval

def test_case_3():

    #Empty text test, zero key + zero nonce test
    #Zero key and zero-nonce test
    key            = '00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 '
    header_counter = '04 00 00 80 00 00 00 01 00 00 00 00 00 00 00 00 '
    aad            = ''
    key            = bytes(bytearray.fromhex(key))
    header_counter = bytearray.fromhex(header_counter)
    aad            = bytearray.fromhex(aad)
    plaintext      = b'\x00'*128


    try:
        ciphertext_hex, digest = our_encryptor(key, header_counter[8:], plaintext, aad)
        ciphertext_hex         = header_counter + ciphertext_hex + digest
        ciphertext_hex         = reverse_bytearray(ciphertext_hex)

        plaintext              = header_counter + plaintext
        plaintext              = reverse_bytearray(plaintext)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": True, "plaintext": plaintext}
        
    except:
        return {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        
def test_case_4():
    
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
        ciphertext_hex         = header_counter + ciphertext_hex + digest
        ciphertext_hex         = reverse_bytearray(ciphertext_hex)

        plaintext              = header_counter + plaintext
        plaintext              = reverse_bytearray(plaintext)

        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": False, "plaintext": plaintext}

    except:
        return {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}

def test_case_5():

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

        plaintext       = header_counter + plaintext
        plaintext       = reverse_bytearray(plaintext)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": True, "plaintext": plaintext}

    except:
        retval = {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        return retval

def test_case_6():
    #Completely randomized data test
    
    global seed
    seed = random.randint(0, 10000)
    print('\n\n\n RANDOM SEED FOR THIS TEST IS', str(seed), '\n\n\n')

    key               = bytes(''.join(random.choice(string.ascii_letters + string.punctuation + string.whitespace + string.digits) for i in range(32)), 'utf-8') 
    header_counter    = '04 XX XX XX XX XX XX 01 XX XX XX XX XX XX XX XX '
    header_counter    = re.sub(r"XX", replace, header_counter)
    aad               = ''
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

        plaintext       = header_counter + plaintext
        plaintext       = reverse_bytearray(plaintext)
        return {"ciphertext": ciphertext_hex, "key": key, "data_valid": True, "plaintext": plaintext}

    except:
        retval = {"ciphertext": b'\x00'*160, "key": b'\x00'*32, "data_valid": False, "plaintext": plaintext}
        return retval


if cocotb.SIM_NAME:    
    factory = TestFactory(run_test)
    factory.add_option("payload_data", [test_case_6]*2 )#, test_case_2, test_case_3, test_case_5, test_case_5, test_case_5, test_case_5, test_case_5, test_case_5, test_case_5, test_case_5])
    factory.add_option("idle_inserter", [None])
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
