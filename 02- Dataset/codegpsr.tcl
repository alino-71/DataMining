## GPSR Options
Agent/GPSR set bdesync_                0.5 ;# beacon desync random component
Agent/GPSR set bexp_                   [expr 3*([Agent/GPSR set bint_]+[Agent/GPSR set bdesync_]*[Agent/GPSR set bint_])] ;# beacon timeout interval
Agent/GPSR set pint_                   1.5 ;# peri probe interval
Agent/GPSR set pdesync_                0.5 ;# peri probe desync random component
Agent/GPSR set lpexp_                  8.0 ;# peris unused timeout interval
Agent/GPSR set drop_debug_             1   ;#
Agent/GPSR set peri_proact_            1 	 ;# proactively generate peri probes
Agent/GPSR set use_implicit_beacon_    1   ;# all packets act as beacons; promisc.
Agent/GPSR set use_timed_plnrz_        0   ;# replanarize periodically
Agent/GPSR set use_congestion_control_ 0
Agent/GPSR set use_reactive_beacon_    0   ;# only use reactive beaconing

set val(bint)           0.5  ;# beacon interval
set val(use_mac)        1    ;# use link breakage feedback from MAC
set val(use_peri)       1    ;# probe and use perimeters
set val(use_planar)     1    ;# planarize graph
set val(verbose)        1    ;#
set val(use_beacon)     1    ;# use beacons at all
set val(use_reactive)   0    ;# use reactive beaconing
set val(locs)           0    ;# default to OmniLS
set val(use_loop)       0    ;# look for unexpected loops in peris

set val(agg_mac)          1 ;# Aggregate MAC Traces
set val(agg_rtr)          0 ;# Aggregate RTR Traces
set val(agg_trc)          0 ;# Shorten Trace File


set val(chan)		Channel/WirelessChannel
set val(prop)		Propagation/TwoRayGround
set val(netif)		Phy/WirelessPhy
set val(mac)		Mac/802_11
set val(ifq)		Queue/DropTail/PriQueue
set val(ll)		LL
set val(ant)		Antenna/OmniAntenna
set val(x)		3100      ;# X dimension of the topography
set val(y)		2000      ;# Y dimension of the topography
set val(ifqlen)		512       ;# max packet in ifq
set val(adhocRouting)	GPSR      ;# AdHoc Routing Protocol
set val(nn)		153       ;# how many nodes are simulated
set val(stop)		300.0     ;# simulation time


set val(agttrc)         ON ;# Trace Agent
set val(rtrtrc)         ON ;# Trace Routing Agent
set val(mactrc)         ON ;# Trace MAC Layer
set val(movtrc)         ON ;# Trace Movement


set val(lt)		""
set val(sc)		"mobility150.tcl"
set val(out)            "outgpsr150.tr"

set src 151
set des 152
set starttime 125
set endtime 185

#set f0 [open throughputgpsr.tr w]
#set f1 [open delaygpsr.tr w]
#set f2 [open pdrgpsr.tr w]

Agent/GPSR set locservice_type_ 3

#add-all-packet-headers
#remove-all-packet-headers
add-packet-header Common Flags IP LL Mac Message GPSR  LOCS SR RTP Ping HLS

Agent/GPSR set bint_                  $val(bint)
# Recalculating bexp_ here
Agent/GPSR set bexp_                 [expr 3*([Agent/GPSR set bint_]+[Agent/GPSR set bdesync_]*[Agent/GPSR set bint_])] ;# beacon timeout interval
Agent/GPSR set use_peri_              $val(use_peri)
Agent/GPSR set use_planar_            $val(use_planar)
Agent/GPSR set use_mac_               $val(use_mac)
Agent/GPSR set use_beacon_            $val(use_beacon)
Agent/GPSR set verbose_               $val(verbose)
Agent/GPSR set use_reactive_beacon_   $val(use_reactive)
Agent/GPSR set use_loop_detect_       $val(use_loop)

CMUTrace set aggregate_mac_           $val(agg_mac)
CMUTrace set aggregate_rtr_           $val(agg_rtr)

# create simulator instance
set ns		[new Simulator]

set loadTrace  $val(lt)

set topo	[new Topography]
$topo load_flatgrid $val(x) $val(y)

set tracefd	[open $val(out) w]

$ns trace-all $tracefd
set namfile [open outgpsr.nam w]
$ns namtrace-all $namfile
$ns namtrace-all-wireless $namfile $val(x) $val(y)
set chanl [new $val(chan)]

# Create God
set god_ [create-god $val(nn)]

# Attach Trace to God
set T [new Trace/Generic]
$T attach $tracefd
$T set src_ -5
$god_ tracetarget $T

#
# Define Nodes
#
puts "Configuring Nodes ($val(nn))"
$ns node-config -adhocRouting $val(adhocRouting) \
                 -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop) \
                 -phyType $val(netif) \
                 -channel $chanl \
		 -topoInstance $topo \
                 -wiredRouting OFF \
		 -mobileIP OFF \
		 -agentTrace $val(agttrc) \
                 -routerTrace $val(rtrtrc) \
                 -macTrace $val(mactrc) \
                 -movementTrace $val(movtrc)

#
#  Create the specified number of nodes [$val(nn)] and "attach" them
#  to the channel. 
for {set i 0} {$i < $val(nn) } {incr i} {
    set node_($i) [$ns node]
    $node_($i) random-motion 0		;# disable random motion
	set ragent [$node_($i) set ragent_]
	$ragent install-tap [$node_($i) set mac_(0)]

    if { $val(mac) == "Mac/802_11" } {      
	# bind MAC load trace file
	[$node_($i) set mac_(0)] load-trace $loadTrace
    }

    # Bring Nodes to God's Attention
    $god_ new_node $node_($i)
}

source $val(sc)

source $val(sc)
$ns at 1.1 "$node_($des) label Des" 
$ns at 1.1 "$node_($src) label Src"
$node_($src) color blue 
$ns at 1.2 "$node_($src) color blue"
$node_($des) color red 
$ns at 1.2 "$node_($des) color red"
#===================================
#        Agents Definition        
#===================================
#Setup a UDP connection
set udp0 [new Agent/UDP]
$ns attach-agent $node_($src) $udp0
set sink [new Agent/LossMonitor]
$ns attach-agent $node_($des) $sink
$ns connect $udp0 $sink
$udp0 set packetSize_ 512

#===================================
#        Applications Definition        
#===================================
#Setup a CBR Application over UDP connection
set cbr0 [new Application/Traffic/CBR]
$cbr0 attach-agent $udp0
$cbr0 set packetSize_ 512
$cbr0 set rate_ 0.1Mb
$cbr0 set random_ null
$ns at $starttime "$cbr0 start"
$ns at $endtime "$cbr0 stop"
    
# Tell nodes when the simulation ends
#
#Define a 'finish' procedure
proc finish {} {
    global ns tracefile namfile f0 f1 f2 
    $ns flush-trace
  # Close Trace Files
      #  close $f0 
      #  close $f1
     #   close $f2
        
 #exec xgraph throughput.tr -x TIME -y throughput -t Throughput -geometry 800x400 &
 #exec xgraph pdr.tr -x TIME -y PDR -t PDR -geometry 800x400 &
 #exec xgraph delay.tr -x TIME -y Delay -t Delay  -geometry 800x400 &
    exec nam outgpsr.nam &
    exit 0
}
for {set i 0} {$i < $val(nn) } { incr i } {
    $ns at $val(stop) "\$node_($i) reset"
}
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "finish"
$ns at $val(stop) "puts \"done\" ; $ns halt"
$ns run
