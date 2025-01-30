# SYNOPSYS
# pspiceng -fileName.in

namespace eval pspiceng { }

proc pspiceng::run {} {
    if {$::argc != 1} {   ;# $::argc holds number of command line arguments
        # wrong number of cl arguments
        puts "\[error\]: Expecting $::argv0 \-fileName.in"
        exit
    } else {
        # received exatcly 1 argument, proceed
        if {[regexp {\-(.*)} [lindex $::argv 0]]} {
            if {[regexp {\-(.*.in)} [lindex $::argv 0] fullMatch fileName]} {   ;# check file extension, must be .in
                    # Input file is a circuit file, proceed
		    #exec cmd.exe /e /r "psp_cmd $fileName >> pspiceng.log"   ;# display product choices dialog box
                    exec cmd.exe /e /r "psp_cmd -product PSpiceAD $fileName >> pspiceng.log"
                } else {
                    # input file is not an .in file
                    puts "\[error\]: Expecting an .in file"
                    exit   
                }
        } else {
            # command line argument does not contain hypen (-)
            puts "\[error\]: Missing hypen \(\-\) in \-fileName.in"
            exit
        }
    }
    return
}

pspiceng::run