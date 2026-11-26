puts "START"
puts $project

set layout [readnet spice $project.lvs.spice]
set source [readnet spice /dev/null]

# top level GL verilog
readnet verilog ../src/ip_pixel_block.v $source

# add any spice files of your analog blocks:
readnet spice ../xschem/lvs/$project.lvs.spice $source

set project [file rootname $project]

lvs "$layout $project" "$source $project" ../../gf180mcu/gf180mcuD/libs.tech/netgen/gf180mcuD_setup.tcl lvs.report -blackbox