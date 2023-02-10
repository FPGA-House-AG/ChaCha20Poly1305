#!/usr/bin/env python
'''
#  BitMonitor class info
## by: Džemil Džigal

This bit monitor class is inspired by official cocotb documentation.
It Observes a single input or output of a DUT. 

## Constructor

Its constructor asks for a name for itself, the signal it monitors,
the clock signal that is connected to the signal it monitors
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

This monitor saves the variable value in its global variable called value_store
'''

from cocotb import coroutine
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb_bus.monitors import Monitor
import cocotb.binary


class BitMonitor(Monitor):

    global value_stored
    
    def __init__(self, name, signal, clock, rise_fall_edge = True, callback=None, event=None):
        self.name = name
        self.signal = signal
        self.clock = clock
        self.rise_fall_edge = rise_fall_edge
        self.value_stored = 'X v Z'
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
            vec = self.signal.value
            if(self.signal.value.is_resolvable):
                print(f"Value of variable: {int(self.signal.value)}")
                value_stored = self.signal.value
            else:
                print(f"Value of variable: UNRESOLVABLE (X or Z)")
                value_stored = 'X v Z'
            self._recv(vec)