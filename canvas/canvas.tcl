# ecg_printer.tcl
# Tcl-Tk app printing a sample ecg waveform in a Canvas. Mainly used to
# test Canvas widget.
#
package require Tk

namespace eval gp_utils {
    proc startup {} {
        # Clear the Screen before starting
        if {[regexp {Windows(.*)} $::tcl_platform(os)]} {
            # Windows OS
            eval exec >&@stdout <@stdin [auto_execok cls]   
        } else {
            # Unix OS
            exec clear >@ stdout
        } 
        puts "\[info\]: Running [info nameofexecutable] \[Version $::tcl_patchLevel\]"
        puts "\[info\]: Executing [pwd]/$::argv0 \[pid [pid]\] on $::tcl_platform(os) OS\n"
        return
    }
}

namespace eval file_utils {
    proc amplify {in gain} {
        return [format %.3f [expr $in * $gain]]
    }
    proc get_points_from_file {fileName char} {
        set fp [open $fileName r]
        while {[gets $fp data] >= 0} {
            set p "[amplify [lindex [split $data $char] 0] 100] [amplify [lindex [split $data $char] 1] 100]"
            set points [lappend points $p]
        }
        close $fp
        return $points
    }
}

namespace eval gui_utils {
    proc setup_toplevel {ar} {
        ttk::setTheme alt
        toplevel .w   ;# Window Widget
        wm title .w "ECG"
        wm geometry .w [lindex [split $ar "x"] 0]x[lindex [split $ar "x"] 1]   ;# width x height
        wm geometry .w "+396+142"   ;# Approximately centered on 1920x1080 display
        wm protocol .w WM_DELETE_WINDOW { exit }
        return
    }
    proc setup_grid {ar} {
        set w [lindex [split $ar "x"] 0]   ;# width
        set h [lindex [split $ar "x"] 1]   ;# height
        set x 0
        while {$x <= $w} {
            .w.c create line $x 0 $x $h -dash . -arrow none -fill gray -smooth true
            set x [expr $x+10]
        }
        #.w.c create line 0 [expr $h/2] $w [expr $h/2] -arrow none -fill gray -smooth true
        set y 0
        while {$y <= $h} {
            .w.c create line 0 $y $w $y -dash . -arrow none -fill gray -smooth true
            set y [expr $y+10]
        }
        return
    }
    proc setup_canvas {ar} {
        canvas .w.c -background lightgrey -width [lindex [split $ar "x"] 0] -height [lindex [split $ar "x"] 1]   ;# width x height
        pack .w.c
        gui_utils::setup_grid $ar   ;# Draw a grid on the canvas
        return
    }
    proc plot {ar points} {
        set h [lindex [split $ar "x"] 1]   ;# height
        set oy [expr $h/2]   
        set x0 0; set y0 $oy   ;# Set origin at the center of the canvas
        foreach point $points {
            set xn [lindex $point 0]
            set yn [expr $oy - [lindex $point 1]]   ;# Shift y coordinate downwards
            .w.c create line $x0 $y0 $xn $yn -arrow none -fill red -smooth true
            set x0 $xn
            set y0 $yn
        }
        return
    }
}

#
# Entry Point
#
proc main {} {
    wm withdraw .   ;# Close master window (.)
    gp_utils::startup   ;# Display startup information
    set points [file_utils::get_points_from_file "ecg.txt" ","]   ;# Setup fileName and splitChar accordingly
    set ar 1000x796   ;# Aspect Ratio
    gui_utils::setup_toplevel $ar
    gui_utils::setup_canvas $ar
    gui_utils::plot $ar $points
}

main   ;# Invoke main procedure to start the script