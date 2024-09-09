package require Tk   ;# GUI widget ToolKit

namespace eval sys_utils {
    proc load_orDb_Dll {} {
        set dllFileName orDb_Dll_Tcl64
        set dllExt .dll
        set cdsRoot [exec cds_root cds_root]   ;# C:\Cadence\SPB_23.1
        set dllPath \\tools\\bin\\   ;# Escape backslash
        if {[file exists $cdsRoot$dllPath$dllFileName$dllExt]} {   ;# C:\Cadence\SPB_23.1\tools\bin\orDb_Dll_Tcl64.dll
            load [file normalize $cdsRoot$dllPath$dllFileName] DboTclWriteBasic
            puts "\[Info\]:  Loading $dllFileName$dllExt"  
        } else {
            puts "\[Error\]: Cannot find $dllFileName$dllExt"
            exit
        }
        return
    }
}

namespace eval gui_utils {
    proc choose_library {} {
        set answer no
        while {$answer == "no"} {
            set types {{{OrCAD Library Files} {.olb}}}
            set windowTitle "Library Browser"
            set filePath [tk_getOpenFile -filetypes $types -title $windowTitle]
            if {$filePath != ""} {
                return $filePath   ;# Full path to selected file
            } else {
                set answer [tk_messageBox -message "Are you sure you want to quit this application?"\
                            -icon question -type yesno -detail "Select \"Yes\" to quit the application"]
                switch -- $answer {
                    yes {return NULL}
                    no { }
                }
            }
        }
    }
}

namespace eval lib_utils {
    proc scan_pkgs {dboLib} {
        set status [DboState]
        set pkgIter [$dboLib NewPackagesIter $status]
        set dboPkg [$pkgIter Next $status]   ;# _DboBaseObject
        set csPkg [DboTclHelper_sMakeCString]   ;# _CString
        while {$dboPkg != "NULL"} {
            $dboPkg GetName $csPkg
            set pkg [DboTclHelper_sGetConstCharPtr $csPkg]   ;# Package Name
            set size [DboPackage_sGetSize $dboPkg $status]   ;# Package Size
            if {$size > 1} {
                # $pkg has multiple parts per package
            }
            # Do your processing on $pkg
            #scan_display_props $dboPkg   ;# PCB Footprint is here
            set dboPkg [$pkgIter Next $status]   ;# Next Package
        }
        delete_DboLibPackagesIter $pkgIter
        return
    }
    proc scan_parts {dboLib} {
        set status [DboState]
        set partIter [$dboLib NewPartsIter $status]
        set dboPart [$partIter NextPart $status]   ;# _DboLibPart
        set csPart [DboTclHelper_sMakeCString]   ;# _CString
        while {$dboPart != "NULL"} {
            $dboPart GetName $csPart
            set part [DboTclHelper_sGetConstCharPtr $csPart]   ;# Part Name
            # Do your processing on $part
            #scan_user_props $dboPart
            #add_user_prop $dboLib $dboPart $part "Prop" "Value"   
            #del_user_prop $dboLib $dboPart $part "Prop"
            set dboPart [$partIter NextPart $status]   ;# Next Part
        }
        delete_DboLibPartsIter $partIter 
        return
    }
    proc scan_symbols {dboLib} {
        set status [DboState]
        set symIter [$dboLib NewSymbolsIter $status]
        set dboSym [$symIter Next $status]   ;# _DboBaseObject
        set csSym [DboTclHelper_sMakeCString]   ;# _CString
        while {$dboSym != "NULL"} {
            $dboSym GetName $csSym
            set sym [DboTclHelper_sGetConstCharPtr $csSym]   ;# Symbol Name
            # Do your processing on $sym
            set dboSym [$symIter Next $status]   ;# Next Symbol
        }
        delete_DboLibSymbolsIter $symIter
        return
    }
    proc scan_cells {dboLib} { 
        set status [DboState]
        set cellIter [$dboLib NewCellsIter $status]
        set dboCell [$cellIter Next $status]   ;# _DboBaseObject
        set csCell [DboTclHelper_sMakeCString]   ;# _CString
        while {$dboCell != "NULL"} {
            $dboCell GetName $csCell
            set cell [DboTclHelper_sGetConstCharPtr $csCell]   ;# Part Name
            # Do your processing on $cell
            set dboCell [$cellIter Next $status]   ;# Next Cell
        }   
        delete_DboLibCellsIter $cellIter
        return
    }
    proc scan_display_props {dboObj} {
        set status [DboState]
        set effPropsIter [$dboObj NewEffectivePropsIter $status] 
        set csEffPropName [DboTclHelper_sMakeCString] 
        set csEffPropValue [DboTclHelper_sMakeCString] 
        set csEffPropType [DboTclHelper_sMakeDboValueType] 
        set csEffEditable [DboTclHelper_sMakeInt] 
        set status [$effPropsIter NextEffectiveProp $csEffPropName $csEffPropValue $csEffPropType $csEffEditable]   ;# first effective property
        while {[$status OK] == 1} { 
            set effPropName [DboTclHelper_sGetConstCharPtr $csEffPropName]
            set effPropValue [DboTclHelper_sGetConstCharPtr $csEffPropValue]
            puts "$effPropName = $effPropValue"
            set status [$effPropsIter NextEffectiveProp $csEffPropName $csEffPropValue $csEffPropType $csEffEditable]   ;# next effective property
        }    
        delete_DboEffectivePropsIter $effPropsIter        
        return
    }
    proc scan_user_props {dboObj} {
        set status [DboState]
        set userPropsIter [$dboObj NewUserPropsIter $status] 
        set dboUserProp [$userPropsIter NextUserProp $status]   ;# first user property (_DboUserProp)
        while {$dboUserProp != "NULL"} { 
            set csUserPropName [DboTclHelper_sMakeCString]   ;# _CString
            $dboUserProp GetName $csUserPropName
            set userPropName [DboTclHelper_sGetConstCharPtr $csUserPropName]   
            set csUserPropValue [DboTclHelper_sMakeCString]   ;# _CString
            $dboUserProp GetStringValue $csUserPropValue
            set userPropValue [DboTclHelper_sGetConstCharPtr $csUserPropValue]
            puts "$userPropName = $userPropValue"
            set dboUserProp [$userPropsIter NextUserProp $status]   ;# next user property
        }    
        delete_DboUserPropsIter $userPropsIter
        return
    }
    proc add_user_prop {dboLib dboObj part propName propValue} {
        set csPropName [DboTclHelper_sMakeCString $propName]
        set csPropValue [DboTclHelper_sMakeCString $propValue]
        set status [$dboObj SetEffectivePropStringValue $csPropName $csPropValue]
        if {[$status OK]} {
            puts "\[Info\]:  Adding $propName to $part"
            #$dboObj MarkModified
            $dboLib SavePart $dboObj   ;# Save changes to part
        }
        return
    }
    proc del_user_prop {dboLib dboObj part propName} {
        set csPropName [DboTclHelper_sMakeCString $propName]
        set status [$dboObj DeleteEffectiveProp $csPropName]
        if {[$status OK]} {
            puts "\[Info\]:  Removing $propName from $part"
            $dboLib SavePart $dboObj   ;# Save changes to part
        }
        return
    }
}

proc main {} {
    eval exec >&@stdout <@stdin [auto_execok cls]   ;# Clear the screen
    wm withdraw .   ;# Close master window
    sys_utils::load_orDb_Dll   ;# Load Dynamic-Link Library
    set olbFileName [gui_utils::choose_library]   ;# Prompt user to choose Capture library
    if {$olbFileName != "NULL"} {  
        set csLibName [DboTclHelper_sMakeCString [file normalize $olbFileName]]   ;# _CString
        set status [DboState]
        set dboSession [DboTclHelper_sCreateSession]   ;# Open _DboSession
        set dboLib [$dboSession GetLib $csLibName $status]   ;# Open _DboLib
        if {[$status Failed]} {
            puts "\[Error\]: Cannot open $olbFileName"
            exit
        } else {
            puts "\[Info\]:  Opening $olbFileName in $dboSession"
            lib_utils::scan_parts $dboLib
            puts "\[Info\]:  Saving $olbFileName"
            set status [$dboSession SaveLib $dboLib]   ;# Save _DboLib
            $dboSession RemoveLib $dboLib   ;# Close _DboLib
            DboTclHelper_sDeleteSession $dboSession   ;# Close _DboSession
            puts "\[Info\]:  Terminating $dboSession succesfully"      
            exit
        }
    } else {
        # User wants to quit
        puts "\[Info\]:  Exiting"
        exit
    }
    return
}

main