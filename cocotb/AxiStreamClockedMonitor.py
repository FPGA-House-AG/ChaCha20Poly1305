#!/usr/bin/env python
'''
#  AxiStreamClockedMonitor class info
## by: Džemil Džigal

This Stream Clocked Monitor class is inspired by official cocotb documentation.
It Observes an AxiStream with the use of an AxiStreamMonitor.
It reacts and reads out the bus status at every clock cycle that it is given
in its constructor. 

## Constructor

Its constructor asks for a name for itself, the Stream it monitors,
the clock signal that is connected to the Stream it monitors
and weather or not should it monitor for rising or falling edges
of the clock signal provided. By default this monitor listens to
the rising edge of the clock signal. 

Aditional arguments are a callback function that is often a model.
This model often generates expected transactions which are then compared
using the Scoreboard class.


## Usage

Add an aditional attribute to your TB object and instantiate the class
with the wanted arguments. For example:

    self.input_mon = BitMonitor("input", dut.input, dut.clk, callback=self.model)


This monitor saves the variable value in its internal variable called value_store
This value_store variable is a python dictionary that contains the following signals
from the source's perspective (ensure that the monitor you're passing to the
constructor is instantiated with the source of the AXI stream):

tdata, tvalid, tready, tlast


The monitor outputs the status of the signals on every rising/falling edge of the
given clock signal. If accessed from the outside, one must consider 
the current clock cycle of the system.

'''

from cocotb import coroutine
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb_bus.monitors import Monitor
import cocotb.binary
from cocotbext.axi import  AxiStreamMonitor


class AxiStreamClockedMonitor(Monitor):

    global value_stored
    
    def __init__(self, name, monitor, clock, rise_fall_edge = True, callback=None, event=None):
        self.name           = name
        self.monitor        = monitor
        self.clock          = clock
        self.rise_fall_edge = rise_fall_edge
        self.callback       = callback
        self.event          = event
        self.value_stored   = {'tdata'  : 'None',
                               'tvalid' : 'None',
                               'tready' : 'None',
                               'tlast'  : 'None'}
        Monitor.__init__(self, callback, event)

    @coroutine
    def _monitor_recv(self):

        #Listen to the rising or falling edge of the clock?
        if(self.rise_fall_edge):
            clkedge = RisingEdge(self.clock)
        else:
            clkedge = FallingEdge(self.clock)

        while True:
            #Capture the wanted signal at RISING/FALLING edge of clock
            yield clkedge
            self.value_stored['tdata']  = str(self.monitor.bus.tdata.value)
            self.value_stored['tvalid'] = str(self.monitor.bus.tvalid.value)
            self.value_stored['tready'] = str(self.monitor.bus.tready)
            self.value_stored['tlast']  = str(self.monitor.bus.tlast)
            self.callback(self.value_stored)
            #print("\nSignal values on the bus (from the source's perspective) are:")
            #for key, value in self.value_stored.items():
            #    print(key, value)