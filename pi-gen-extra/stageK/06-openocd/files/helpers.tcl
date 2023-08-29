Copyright 2017-2023 Marcel Ball

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# helper script to get Live Watch to work in VSCode
#
# this tcl script is taken from https://github.com/Marus/cortex-debug/blob/master/support/openocd-helpers.tcl
# 
# See also https://github.com/Marus/cortex-debug/issues/810

#
# CDLiveWatchSetup
#    This function must be called before the init is called and after all the targets are created. You can create
#    a custom version of this function (even empty) if you already setup the gdb-max-connections elsewhere
#
#    We increment all gdb-max-connections by one if it is already a non-zero. Note that if it was already set to -1,
#    we leave it alone as it means unlimited connections
#
proc CDLiveWatchSetup {} {
    try {
        foreach tgt [target names] {
            set nConn [$tgt cget -gdb-max-connections]
            if { $nConn > 0 } {
                incr nConn
                $tgt configure -gdb-max-connections $nConn
                puts "[info script]: Info: Setting gdb-max-connections for target '$tgt' to $nConn"
            }
        }
    } on error {} {
        puts stderr "[info script]: Error: Failed to increase gdb-max-connections for current target. Live variables will not work"
    }
}
