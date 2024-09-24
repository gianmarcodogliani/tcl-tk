# Paste these procedure inside OrCAD X Presto's Command Window to use Allegro-like syntax for drawing commands.

proc x {x y} {variable p; set p "$x $y"; pcb::cmd "pick grid $x $y"; pcb::cmd "trapsize"}

proc ix {os} {variable p; set p "[expr [lindex $p 0] + $os] [lindex $p 1]"; pcb::cmd "pick grid [lindex $p 0] [lindex $p 1]"; pcb::cmd "trapsize"}

proc iy {os} {variable p; set p "[lindex $p 0] [expr [lindex $p 1] + $os]"; pcb::cmd "pick grid [lindex $p 0] [lindex $p 1]"; pcb::cmd "trapsize"}
