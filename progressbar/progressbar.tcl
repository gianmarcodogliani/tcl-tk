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

namespace eval gui_utils {
    proc setup_toplevel {} {
        ::ttk::setTheme alt
        toplevel .w   ;# Window Widget
        #wm iconphoto .w -default [logo_utils::create_git_logo]   ;# From gitlogo.tcl
        wm title .w "progressbar"
        wm geometry .w 280x110   ;# Aspect Ratio definition
        wm protocol .w WM_DELETE_WINDOW { exit }   ;# Quit app when user press "X"
        return
    }
    proc setup_pbar {} {
        variable progress 0
        variable curr_progess "0%"
        ttk::progressbar .w.pb -orient horizontal -mode determinate \
            -length 200 -variable gui_utils::progress -value 0   ;# *scope resolution gui_utils::progress*
        grid .w.pb -padx 20 -pady 20 -row 0 -column 0   ;# Shift 20 pixels down and rightward
        ttk::label .w.l -textvariable gui_utils::curr_progess
        grid .w.l  -row 0 -column 1
        return
    }
    proc update_pbar {} {
        if {$gui_utils::progress >= 100} {
            set msg [tk_messageBox -title "Info" -message "Loading Completed!" -icon info -type ok]
            switch -- $msg {
                ok exit
            }
        }
        set gui_utils::progress [expr $gui_utils::progress+20]
        set gui_utils::curr_progess "$gui_utils::progress\%"
        update
        return
    }
    proc setup_button {} {
        ttk::button .w.b -text "Load Progressbar" -command "gui_utils::update_pbar"
        grid .w.b
        return
    }
}   

#
# Entry Point
#
proc main {} {
    wm withdraw .   ;# Close master window (.)
    gp_utils::startup   ;# Display startup information
    gui_utils::setup_toplevel
    gui_utils::setup_pbar
    gui_utils::setup_button
}

main   ;# Invoke main procedure to start the script
