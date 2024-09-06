# xlsx_reader.tcl
# Tcl-Tk app reading an Excel .xlsx file and dynamically updating an
# indeterminate progressbar to keep user informed about the process.
# The .xlsx file name must be passed as a command line argument, i.e.
# tclsh xlsx_reader.tcl -testFile.xlsx.
# 
# Compatible with Windows operating systems only.
#
package require dde   ;# Dynamic Data Exchange
package require Tk    ;# GUI Widgets ToolKit

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
        puts "\[info\]:  Running [info nameofexecutable] \[Version $::tcl_patchLevel\]"
        puts "\[info\]:  Executing [pwd]/$::argv0 \[pid [pid]\] on $::tcl_platform(os) OS\n"
        return
    }
}

namespace eval sys_utils {
    proc get_proc_pid {procName} {
        set procList [exec tasklist]   ;# Run tasklist.exe
        set procIdx [lsearch $procList $procName]
        if {$procIdx < 0} {
            # Process not found
            return NULL
        } else {
            # Return process id
            return [lindex $procList [expr $procIdx + 1]]
        } 
    }
    proc kill_proc {procName} {
        set pid [get_proc_pid $procName]
        if {$pid != "NULL"} {
            exec [auto_execok taskkill] /PID $pid /F
        } else {
            puts "\[error\]: Cannot find $procName"
        }
        return
    }
}

namespace eval gui_utils {
    proc setup_pbar {} {
        toplevel .w   ;# Window Widget
        wm title .w "xlsx Reader"
        wm geometry .w 250x85   ;# Aspect Ratio definition
        ttk::progressbar .w.pb -orient horizontal -mode indeterminate \
            -length 200 -variable gui_utils::progress -value 0   ;# *scope resolution gui_utils::progress*
        pack .w.pb -pady 20   ;# Shift 20 pixels down
        ttk::label .w.l -textvariable gui_utils::text
        pack .w.l
        return .w
    }
    proc update_pbar {} {
        incr gui_utils::progress   ;# *scope resolution gui_utils::progress*
        update
    }
}

namespace eval xlsx_utils {
    proc get_xlsx_page_names {rawPageNames} {
        set tmpPageList [lrange [split $rawPageNames "\t"] 1 end-1]   ;# Skip first ([:]:) and last (System) items
        foreach tmpPage $tmpPageList {   ;# tmpPage is in the form [fileName.xlsx]pageName
            regexp {\[.*\](.*)} $tmpPage fullMatch pageName
            set pageList [lappend pageList $pageName]
        }
        return $pageList
    }
    proc read_xlsx_file_pages {pageName} {
        set c 1   ;# Column index
        set r 1   ;# Row index
        # To read a cell in a page --> eval "dde request -binary Excel "\pageName" "RrCc"" 
        if {[llength [eval "dde request -binary Excel \"\\$pageName\" [string cat \"R$r C$c\"]"]] == 1} {   ;# Query A1 cell
            # A1 cell is empty, page is assumed to be empty
            return NULL
        } else {
            # Page is assumed to have some content
            set stop false   ;# Stop flag
            while {$stop == "false"} { 
                if {[llength [eval "dde request -binary Excel \"\\$pageName\" [string cat \"R$r C[expr $c+1]\"]"]] == 1} {   ;# Query first cell of adjacent column
                    # First cell in adjacent column is empty, current column is assumed to be last column
                    set stop true
                }
                while {[llength [eval "dde request -binary Excel \"\\$pageName\" [string cat \"R$r C$c\"]"]] > 1} {   ;# Query current cell
                    # Current cell is non-empty, extract its content
                    set cmdTopics "dde request -binary Excel \"\\$pageName\" [string cat \"R$r C$c\"]"   ;# Returns current cell content
                    set cell [eval $cmdTopics]
                    set cellsPerColumn [lappend cellsPerColumn [lindex $cell 0]] 
                    incr r   ;# Next row
                    gui_utils::update_pbar   ;# Update progressbar
                }
                set cellsPerPage [lappend resPerPage $cellsPerColumn]
                set cellsPerColumn [list]   ;# Reset
                set r 1   ;# Reset row index 
                incr c   ;# Next column
            }
        }
        return $cellsPerPage
    }
    proc read_xlsx_file {fileName} {
        if {[file exists $fileName]} {
            # fileName.xlsx has been found, proceed
            if {![catch {exec cmd.exe /e /r start excel [file native $fileName]}]} {   ;# Open fileName.xlsx with Excel using Windows cmd Prompt
                after 1000   ;# Wait for 1s before sending dde commands
                set w [gui_utils::setup_pbar]   ;# Setup progressbar to keep user informed
                # To get list of raw page names --> eval "dde request -binary Excel System {Topics}"
                set pageList [xlsx_utils::get_xlsx_page_names [eval "dde request -binary Excel System {Topics}"]]   ;# List of raw, tabbed (\t) page names          
                foreach page $pageList {   ;# Iterate on exact page names
                    set gui_utils::text "Reading $page"
                    set pageContentPerColumns [lappend pageContentPerColumns [xlsx_utils::read_xlsx_file_pages $page]]   ;# Get page content
                }
                # To close Excel file --> eval "dde execute Excel System {[CLOSE(FALSE)]}"
                eval "dde execute Excel System {\[CLOSE(FALSE)\]}"
                sys_utils::kill_proc "EXCEL.EXE"   ;# Close Excel process
                destroy $w   ;# Destroy progressbar
                set retList [lappend retList $pageList]      ;# Prepare return list
                set retList [lappend retList $pageContentPerColumns]   ;# Prepare return list
                return $retList
            } else {
                # Excel application not found
                puts "\[error\]: EXCEL.EXE not found"
                exit
            }
        } else {
            # fileName.xlsx cannot be found inside current working directory
            puts "\[error\]: Cannot find $fileName in [pwd]"
            exit
        }
    }
}

#
# Entry Point
#
proc main {} {
    set tStart [clock clicks]   ;# To keep track of execution time
    wm withdraw .   ;# Close master window (.)
    gp_utils::startup   ;# Display startup information
    if {[regexp {Windows(.*)} $::tcl_platform(os)]} {
        # Windows OS
        if {$::argc != 1} {   ;# argc holds no of cl arguments
            # Wrong no of cl arguments
            puts "\[error\]: Expecting $::argv0 \-fileName.xlsx"
            exit
        } else {
            # Received exatcly 1 arg, proceed
            if {[regexp {\-(.*)} [lindex $::argv 0]]} {
                if {[regexp {(.*).xlsx} [lindex $::argv 0] fullMatch fileName]} {   ;# Check file extension, must be .xlsx
                    # Input file is an xlsx file, proceed
                    set retList [xlsx_utils::read_xlsx_file [string range [lindex $::argv 0] 1 end]]   ;# Remove hypen (-) char from cl arg
                    set pageList [lindex $retList 0]
                    set pageContentPerColumns [lindex $retList 1]
                    # User Code Section begins here
                    #
                    # Do your processing on pageContentPerColumns
                    #
                    # User Code Section ends here
                    set tStop [clock clicks]   ;# To keep track of execution time
                    puts "\[info\]:  Terminating succesfully in [format %.2f [expr ($tStop - $tStart)*1e-6]] seconds"   ;# Clock Clicks are in us
                    exit
                } else {
                    # Input file is not an xlsx file
                    puts "\[error\]: Expecting an .xlsx file"
                    exit   
                }
            } else {
                # Cl arg does not contain hypen (-)
                puts "\[error\]: Missing hypen \(\-\) in \-fileName.xlsx"
                exit
            }
        }
    } else {
        # Unix OS
        puts "\[error\]: Expecting Windows OS"
        exit   
    }
}

main   ;# Invoke main procedure to start the script