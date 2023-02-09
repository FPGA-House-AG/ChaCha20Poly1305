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
#from BitMonitor import BitMonitor
#from AxiStreamClockedMonitor import AxiStreamClockedMonitor

class TB(object):
    def __init__(self, dut):
        self.dut = dut

        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        cocotb.fork(Clock(dut.clk, 4, units="ns").start())
        self.__next_is_sop__ = False
        # connect TB source to DUT sink, and vice versa
        # byte_lanes = 16 is workaround for https://github.com/alexforencich/cocotbext-axi/issues/46
        
        #self.source  = AxiStreamSource (AxiStreamBus.from_prefix(dut, "sink"),     dut.clk, dut.reset, byte_lanes = 64)
        #self.sink    =   AxiStreamSink (AxiStreamBus.from_prefix(dut, "source"  ), dut.clk, dut.reset, byte_lanes = 16)
        
        #This monitor is instantiated "from the Source side". Thus it effectively only has signals relevant to the source.
        #self.monitor = AxiStreamMonitor(AxiStreamBus.from_prefix(dut, "source" ), dut.clk, dut.reset)
        
        #Instantiate the signal sniffers through the use of BitMonitor class or bus sniffers with the use of AxiStreamClockedMonitor class
        #self.source_bus_tlast_monitor = BitMonitor("source_bus_tlast", self.source.bus.tlast, self.dut.clk, True, callback=self.model)
        #self.source_sink_bus_monitor = AxiStreamClockedMonitor("source_sink_bus", self.monitor, self.dut.clk, True, callback=self.callback_function, event=None)

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
        self.dut.reset.setimmediatevalue(0)
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.reset.value = 1
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)
        self.dut.reset.value = 0
        await RisingEdge(self.dut.clk)
        await RisingEdge(self.dut.clk)


async def run_test(dut, payload_lengths=None, payload_data=None, header_lengths=None, idle_inserter=None):

    tb = TB(dut)

    '''

    tb.dut.sink_length =   BinaryValue(16, n_bits = 12, bigEndian = False)

    await tb.reset()    
    
    tb.set_idle_generator(idle_inserter)


    tb.log.info("Payload lengths is %s" % payload_lengths()[0])
    test_pkts = []
    test_frames = []
    sink_length_ref_val = tb.dut.sink_length.value.binstr
    source_length_ref_val = tb.dut.source_length.value.binstr

    for pkt_len in payload_lengths():
        payload = payload_data(pkt_len)
        test_pkt = bytearray(payload)
        test_pkts.append(test_pkt)

        sink_length_test_val = tb.dut.sink_length.value.binstr
        source_length_test_val = tb.dut.source_length.value.binstr

        test_frame = AxiStreamFrame(test_pkt)
        test_frames.append(test_frame)

        await tb.source.send(test_pkt)
        await tb.source.wait()

        assert sink_length_ref_val == sink_length_test_val
        assert source_length_ref_val == source_length_test_val
        assert tb.source.bus.tlast.value  == 1
        assert tb.source.bus.tready.value == 1
        assert tb.source.bus.tvalid.value == 1 
        

    tb.log.info("Waiting to receive packet on our sink.")
    assert ~tb.sink.empty()

    while(not tb.sink.empty()):
        if(tb.sink.bus.tready == 1 and tb.sink.bus.tvalid == 1):
            rx_frame = await tb.sink.recv()
            tb.log.info("Got data from source")
            tb.log.info("Output Payload length is: %s bytes or %s bits \n" % (str(len(rx_frame)), str(len(rx_frame) * 8)))
            sink_length_test_val = tb.dut.sink_length.value.binstr
            source_length_test_val = tb.dut.source_length.value.binstr
            assert sink_length_ref_val == sink_length_test_val
            assert source_length_ref_val == source_length_test_val
            rx_pkt = bytes(rx_frame)
        else:
            tb.log.info("Sink not ready to recieve data")
            await RisingEdge(tb.dut.clk)


    #Clean in/out buffer test
    assert tb.source.empty()
    assert tb.sink.empty()
    #Expand the test a bit to see if any "trailing errors" occured
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    #Final test, source and sink should be ready to send and to recieve but nothing should
    #be sent anymore since the buffers are empty.
    assert tb.source.bus.tlast.value == 0
    assert tb.source.bus.tready.value == 1
    assert tb.source.bus.tvalid.value == 0
    assert tb.sink.bus.tlast.value == 0
    assert tb.sink.bus.tready.value == 1
    assert tb.sink.bus.tvalid.value == 0
    '''

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])


def size_list():
    return list(range(1, 129))

def payload_size_list_t1():
    #here we define the payload size 128 = 16 * 8b,
    return list(range(16, 17))

def payload_size_list_t2():
    return list(range(32, 33))
    

def header_size_list():
    return list(range(1, 4))


def incrementing_payload_256(length):
    return bytearray(itertools.islice(itertools.cycle(range(0, 256)), length))

def incrementing_payload_128(length):
    return bytearray(itertools.islice(itertools.cycle(range(0, 128)), length))


if cocotb.SIM_NAME:

    factory = TestFactory(run_test)
    #factory.add_option("payload_lengths", [payload_size_list_t1, payload_size_list_t2])
    #factory.add_option("payload_data", [incrementing_payload_256, incrementing_payload_256])
    #factory.add_option("idle_inserter", [None, cycle_pause])
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
