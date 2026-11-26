IP_FILES     := $(wildcard ip_*.sch)
LVS_FILES    := $(IP_FILES:%.sch=lvs/%.lvs.spice)
PARAX_FILES  := $(IP_FILES:%.sch=parax/%.sim.spice)

.PHONY: cleanlvs cleanparax

###################################################################################
## LVS Netlist Generation
###################################################################################

cleanlvs:
	rm -f $(LVS_FILES)

lvs: $(LVS_FILES)
	sed -i "s/area='13.5u \* 13.5u '/area=0.16125n/" lvs/ip_pixel_nd2ps.lvs.spice
	cp lvs/ip_pixel_nd2ps.lvs.spice lvs/ip_pixel_nd2ps_dummy.lvs.spice
	sed -i 's/ip_pixel_nd2ps/ip_pixel_nd2ps_dummy/g' lvs/ip_pixel_nd2ps_dummy.lvs.spice

lvs/%.lvs.spice: %.sch
	xschem -x -q $< --command "set lvs_netlist 0; set top_is_subckt 1; xschem netlist -file $*.lvs.spice"
	mv simulation/$*.lvs.spice lvs/$*.lvs.spice

###################################################################################
## Parax Simulation Generation
###################################################################################

cleanparax:
	rm -f ./parax/*.spice
	rm -f ./parax/*.sim

parax: $(PARAX_FILES)

parax/%.sim.spice: ../mag/%.mag
	cd ../mag && magic -rcfile .magicrc -noconsole -dnull tcl/extract_for_sim.tcl $*
	cd ../mag && rm -f $*.ext
	mv ../mag/$*.sim.spice ./parax
	mv ../mag/$*_parax.sim ./parax
	rm -f ../mag/$*_parax.res.ext
	rm -f ../mag/$*_parax.ext
	rm -f ../mag/$*_parax.nodes
