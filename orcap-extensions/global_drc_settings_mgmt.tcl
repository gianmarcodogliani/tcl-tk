namespace eval global_drc_settings { 
    proc set_global_drc_settings_value {home ver value} {
        set iniOri "\\cdssetup\\OrCAD_Capture\\$ver\\Capture.ini"
        set iniBak "\\cdssetup\\OrCAD_Capture\\$ver\\Capture.bak"
        file rename -force $home$iniOri $home$iniBak   ;# Overwrite
        set fp0 [open $home$iniBak r]; set fp1 [open $home$iniOri w]
        while {[gets $fp0 data] > 0} {
            if {[regexp {UseGlobalDRCSettings=} $data]} {
                puts $fp1 "UseGlobalDRCSettings=$value"
            } else {
                puts $fp1 $data
            }
        }
        close $fp1; close $fp0
        return
    }
    proc get_global_drc_settings_value {home ver} {
        set iniOri "\\cdssetup\\OrCAD_Capture\\$ver\\Capture.ini"
        set fp [open $home$iniOri r]
        while {[gets $fp data] > 0} {
            if {[regexp {UseGlobalDRCSettings=(.*)} $data fullMatch value]} {
                close $fp
                return $value
            }
        }
        close $fp
        return NULL   ;# Global DRC Settings value not found
    }
    proc get_capture_version {} {
        set spb [lindex [split [info nameofexecutable] /] end-3]   ;# SPB_XX.X 
        regexp {SPB_(.*)} $spb fullMatch ver
        return "$ver.0"   ;# XX.X.0
    }
    proc get_env_var_value {var} {
        return $::env($var)   ;# Global Namespace
    }
    proc enable_global_drc_settings {} {
        package require Tk   ;# GUI Widget ToolKit
        wm withdraw .   ;# Close master window
        if {![catch {set home [get_env_var_value HOME]}]} {
            # Variabile HOME exists
        } else {
            # Variable HOME does not exist
            set home [get_env_var_value USERPROFILE]
        }
        set ver [get_capture_version]
        set drcSettings [get_global_drc_settings_value $home $ver]
        switch $drcSettings {
            True { return }
            False {
                set ans [tk_messageBox -title Warning -icon warning -type yesno\
                                       -message "Global DRC Settings are disabled,\nWould you like to turn them On?"\
                                       -detail "Note: Capture will be closed."]
                switch -- $ans {
                    no { return }
                    yes {
                        set_global_drc_settings_value $home $ver True
                        Menu "File::Exit"   ;# Close capture.exe
                        return
                    } 
                }
            }
            NULL {
                set ans [tk_messageBox -title Error -icon error -type ok\
                                       -message "Global DRC Settings not found."]
                switch -- $ans {
                    ok { return }
                }
            }
            default {
                return
            }    
        }
    }
}

global_drc_settings::enable_global_drc_settings   ;# Invoke main procedure

# From now on it is possible to turn off online drcs globally using writeProfileString {DRCSettings} {RUN_Online_Rules} {FALSE}