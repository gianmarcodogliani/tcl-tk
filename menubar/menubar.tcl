# menubar.tcl
# Tcl-Tk app setting up a menubar and a text area which acts as a log.
# File > Open | Exit
# Edit > Clear Log
# Help > About | Documentation
# 
# Compatible with Windows/Mac/Linux operating systems. On Windows, the
# application uses GitHub logo as window icon photo.
#
package require Tk
source gitlogo.tcl

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
namespace eval sys_utils {
    proc get_time {} {
        return "\[[clock format [clock seconds] -format %T]\]"   ;# hh:mm:ss
    }
}
namespace eval menu_commands {
    proc f_open {} {
        set windowTitle "File Browser"
        set filePath [tk_getOpenFile -title $windowTitle]
        if {$filePath != ""} {
            .w.f.txt insert end "[sys_utils::get_time] Opening $filePath\n"
        }
        return $filePath
    }
    proc e_clear_log {} {
        .w.f.txt delete 0.0 end
        return
    }
    proc h_documentation {} {
        set pdfDoc "./sample.pdf"
        if {[regexp {Windows(.*)} $::tcl_platform(os)]} {
            # Windows OS
            set command [list {*}[auto_execok start] {}]
            exec {*}$command $pdfDoc & 
        } elseif {[regexp {Linux(.*)} $::tcl_platform(os)]} {
            # Linux OS
            exec evince $pdfDoc
        } else {
            # MAC OS
            open $pdfDoc
        }
        return
    }
    proc h_about {} {
        .w.f.txt insert end "[sys_utils::get_time] [pwd]/$::argv0 \[pid [pid]\]\n"
        .w.f.txt insert end "[sys_utils::get_time] [info nameofexecutable]\n   \[Version $::tcl_patchLevel\] $::tcl_platform(os) OS\n"
        return
    }
}
namespace eval gui_utils {
    proc setup_toplevel {} {
        ttk::setTheme alt
        toplevel .w   ;# Window Widget
        if {[regexp {Windows(.*)} $::tcl_platform(os)]} {
            # Windows OS
            wm iconphoto .w -default [logo_utils::create_git_logo]   ;# From gitlogo.tcl
        }
        wm title .w "menubar"
        wm geometry .w 435x345   ;# Aspect Ratio definition
        wm protocol .w WM_DELETE_WINDOW { exit }   ;# Quit app when user press "X"
        return
    }
    proc setup_menubar {} {
        menu .mb   ;# Menubar Widget
        # Begin add cascade section
        .mb add cascade -label File -menu [menu .mb.file -tearoff 0] -underline 0   ;# Press "alt" to reveal underline
        .mb add cascade -label Edit -menu [menu .mb.edit -tearoff 0] -underline 0   ;# Press "alt" to reveal underline
        .mb add cascade -label Help -menu [menu .mb.help -tearoff 0] -underline 0   ;# Press "alt" to reveal underline
        # End add cascade section
        # File command section
        .mb.file add command -label Open -command menu_commands::f_open -underline 0 -accelerator ""
        .mb.file add separator
        .mb.file add command -label Exit -command { exit } -underline 0 -accelerator "Alt+F+E"
        # Edit command section
        .mb.edit add command -label "Clear Log" -command menu_commands::e_clear_log -underline 0 -accelerator ""
        # Help command section
        .mb.help add command -label About -command menu_commands::h_about
        .mb.help add command -label Docs -command menu_commands::h_documentation

        .w config -menu .mb  ;# Hook menu to Window Widget
        return
    }
    proc setup_txtarea {} {
        frame .w.f   ;# Frame Widget
        #text .w.f.txt -width 50 -height 20 -yscroll ".w.f.vsb set" -xscroll ".w.f.hsb set"   ;# Text Widget
        text .w.f.txt -width 50 -height 20 -yscroll ".w.f.vsb set"   ;# Text Widget
        scrollbar .w.f.vsb -orient vertical -command ".w.f.txt yview"   ;# Scrollbar Widget
        #scrollbar .w.f.hsb -orient horizontal -command ".w.f.txt xview"   ;# Scrollbar Widget
        grid .w.f.txt .w.f.vsb -sticky ns   ;# -sitcky to expand from north to south
        #grid .w.f.txt .w.f.hsb -sticky ew
        grid .w.f -padx 10 -pady 10
        return
    }
}   

#
# Entry Point
#
proc main {} {
    wm withdraw .   ;# Close master window (.)
    gui_utils::setup_toplevel
    gui_utils::setup_menubar
    gui_utils::setup_txtarea
    return
}

main   ;# Invoke main procedure to start the script