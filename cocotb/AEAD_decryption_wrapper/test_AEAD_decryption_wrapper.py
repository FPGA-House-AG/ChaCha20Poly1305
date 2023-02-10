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
import binascii


#Provides standard python unit testing capabilities for cocotb. Source: https://pypi.org/project/cocotb-test/
import cocotb_test.simulator

import asyncio
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.regression import TestFactory
from cocotb.binary import BinaryValue
from cocotb.result import TestError

from cocotbext.axi import AxiStreamBus, AxiStreamFrame, AxiStreamSource, AxiStreamSink, AxiStreamMonitor
import sys
sys.path.insert(0, "..")
from BitMonitor import BitMonitor
from AxiStreamClockedMonitor import AxiStreamClockedMonitor

class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.fork(Clock(dut.clk, 4, units="ps").start())
        self.__next_is_sop__ = False

        # connect TB source to DUT sink, and vice versa
        # byte_lanes = 16 is workaround for https://github.com/alexforencich/cocotbext-axi/issues/46

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
        
        #raise TestError("TESTING IF ERROR RAISING WORKS")


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

async def run_test(dut, payload_lengths=None, payload_data=None, header_lengths=None, idle_inserter=None):

    tb = TB(dut)
    #tb.dut.sink_length =   BinaryValue(16, n_bits = 12, bigEndian = False)

    await tb.reset()    
    tb.set_idle_generator(idle_inserter)
    tb.log.info("Payload lengths is (16bytes cycles) %s" % payload_lengths())
    tb.log.info("Length of plaintext is (bytes): %s" % len(payload_data()))
    tb.log.info("Number of AXI transfers (handshakes): %s" % str(payload_lengths()))
    
    test_pkts = []
    test_frames = []

    payload = bytearray(payload_data())
    key = payload_data(0)["key"]
    tb.dut.in_key = BinaryValue(value=key, n_bits=len(key) * 8)
    test_frame = AxiStreamFrame(payload)#, tx_complete=print("COMPLETED TX EVENT"))
    await tb.source.send(test_frame)
    await tb.source.wait()
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)

    rx_frame = await tb.sink.recv()
    rx_frame = reverse_bytearray(rx_frame.tdata)
    print(rx_frame)
    for i in range(10):
        await RisingEdge(tb.dut.clk)


def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


def size_list():
    return list(range(1, 129))

def payload_size_list_t1():
    #here we define the payload size 160 = 16bytes * 10cycles,
    return 10

def payload_size_list_t2():
    return list(range(32, 33))
    

def header_size_list():
    return list(range(1, 4))

def incrementing_payload_256(length):
    return bytearray(itertools.islice(itertools.cycle(range(0, 256)), length))

def incrementing_payload_128(length):
    return bytearray(itertools.islice(itertools.cycle(range(0, 128)), length))


def reverse_bytearray(byte_array):
    info = [byte_array[i : i + 16] for i in range(0, len(byte_array), 16)]
    for i in range(0, len(info)):
        info[i].reverse()
    #info = bytes(info)
    return bytearray(b''.join(info))



def plaintext_bytearray_key_1(index = None):
    

    plaintext_hex = '04 00 00 80 00 00 00 01 40 41 42 43 44 45 46 47 '
    plaintext_hex+= 'a4 79 cb 54 62 89 46 d6 f4 04 2a 8e 38 4e f4 bd ' 
    plaintext_hex+= '2f bc 73 30 b8 be 55 eb 2d 8d c1 8a aa 51 d6 6a ' 
    plaintext_hex+= '8e c1 f8 d3 61 9a 25 8d b0 ac 56 95 60 15 b7 b4 ' 
    plaintext_hex+= '93 7e 9b 8e 6a a9 57 b3 dc 02 14 d8 03 d7 76 60 ' 
    plaintext_hex+= 'aa bc 91 30 92 97 1d a8 f2 07 17 1c e7 84 36 08 ' 
    plaintext_hex+= '16 2e 2e 75 9d 8e fc 25 d8 d0 93 69 90 af 63 c8 ' 
    plaintext_hex+= '20 ba 87 e8 a9 55 b5 c8 27 4e f7 d1 0f 6f af d0 ' 
    plaintext_hex+= '46 47 1b 14 57 76 ac a2 f7 cf 6a 61 d2 16 64 25 ' 
    plaintext_hex+= '2f b1 f5 ba d2 ee 98 e9 64 8b b1 7f 43 2d cc e4 '
    plaintext = bytearray.fromhex(plaintext_hex)
    
    plaintext = reverse_bytearray(plaintext)

    #print(", ".join(hex(b) for b in plaintext).replace('\\x', ' ').replace('0x', ' '))
    #        var packet_length = 64 + 64 + 16 + 16 // bytes 128+32 = 160


    #plaintext = b'\x4c\x61\x64\x69\x65\x73\x20\x61\x6e\x64\x20\x47\x65\x6e\x74\x6c\x65\x6d\x65\x6e\x20\x6f\x66\x20\x74\x68\x65\x20\x63\x6c\x61\x73\x73\x20\x6f\x66\x20\x27\x39\x39\x3a\x20\x49\x66\x20\x49\x20\x63\x6f\x75\x6c\x64\x20\x6f\x66\x66\x65\x72\x20\x79\x6f\x75\x20\x6f\x6e\x6c\x79\x20\x6f\x6e\x65\x20\x74\x69\x70\x20\x66\x6f\x72\x20\x74\x68\x65\x20\x66\x75\x74\x75\x72\x65\x2c\x20\x73\x75\x6e\x73\x63\x72\x65\x65\x6e\x20\x77\x6f\x75\x6c\x64\x20\x62\x65\x20\x69\x74\x2e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    key = b'\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F'

    #print(plaintext)
    #return b'\x4c\x61\x64\x69\x65\x73\x20\x61\x6e\x64\x20\x47\x65\x6e\x74\x6c\x65\x6d\x65\x6e\x20\x6f\x66\x20\x74\x68\x65\x20\x63\x6c\x61\x73\x73\x20\x6f\x66\x20\x27\x39\x39\x3a\x20\x49\x66\x20\x49\x20\x63\x6f\x75\x6c\x64\x20\x6f\x66\x66\x65\x72\x20\x79\x6f\x75\x20\x6f\x6e\x6c\x79\x20\x6f\x6e\x65\x20\x74\x69\x70\x20\x66\x6f\x72\x20\x74\x68\x65\x20\x66\x75\x74\x75\x72\x65\x2c\x20\x73\x75\x6e\x73\x63\x72\x65\x65\x6e\x20\x77\x6f\x75\x6c\x64\x20\x62\x65\x20\x69\x74\x2e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    if(index is not None):
        index = int(index)
        return {"plaintext": plaintext[index*16 : index*16 + 16], "key": key}
    else:
        return plaintext


if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    factory.add_option("payload_lengths", [payload_size_list_t1])#, payload_size_list_t2])
    factory.add_option("payload_data", [plaintext_bytearray_key_1])#, incrementing_payload_256])
    factory.add_option("idle_inserter", [None])#, cycle_pause])
    factory.generate_tests()


# cocotb-test
tests_dir = os.path.dirname(__file__)
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..'))



def test_AEAD_decryption_wrapper(request):
    dut = "AEAD_decryption_wrapper"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.vhd"),
    ]

    parameters = {}

    #parameters['DATA_WIDTH'] = 16 * 8 #512
    # divide by 8?
    #parameters['KEEP_WIDTH'] = parameters['DATA_WIDTH'] / 8

    #extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}
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
