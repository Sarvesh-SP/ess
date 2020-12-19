if {$argc != 1} {
error "Command: ns <ScriptName.tcl> <Number_of_Nodes>"
exit 0
}
set ns [new Simulator]
set tracefile [open ess.tr w]
$ns trace-all $tracefile
set namfile [open ess.nam w]
$ns namtrace-all-wireless $namfile 750 750
proc finish {} {
global ns tracefile namfile
$ns flush-trace
close $tracefile
close $namfile
exec nam ess.nam &
exec awk -f ess.awk ess.tr &
exit 0
}
#get the number of nodes value from the user
set val(nn) [ lindex $argv 0]
#create new topography object
set topo [new Topography]
$topo load_flatgrid 750 750
#Configure the nodes
$ns node-config -adhocRouting AODV \
-llType LL \
-macType Mac/802_11 \
-ifqType Queue/DropTail \
-channelType Channel/WirelessChannel \
-propType Propagation/TwoRayGround \
-antType Antenna/OmniAntenna \
-ifqLen 50 \
-phyType Phy/WirelessPhy \
-topoInstance $topo \
-agentTrace ON \
-routerTrace ON \
-macTrace OFF \
-movementTrace ON
#general operational descriptor storing the hop details in the
set god_ [create-god $val(nn)]
#create mobile nodes
for {set i 0} {$i < $val(nn)} {incr i} {
set n($i) [$ns node]
}
#label node
$n(1) label "TCPSource"
$n(3) label "Sink"
#Randomly placing the nodes
for {set i 0} {$i<$val(nn)} {incr i} {
set XX [expr rand()*750]
set YY [expr rand()*750]
$n($i) set X_ $XX
$n($i) set Y_ $YY
}
#define the initial position for the nodes
for {set i 0} {$i < $val(nn)} {incr i} {
$ns initial_node_pos $n($i) 100
}
#define the destination procedure to set the destination to each node
proc destination {} {
global ns val n
set now [$ns now]
set time 5.0
for {set i 0} {$i < $val(nn)} {incr i} {
set XX [expr rand()*750]
set YY [expr rand()*750]
$ns at [expr $now + $time] "$n($i) setdest $XX $YY 20.0"
}
$ns at [expr $now + $time] "destination"
}
set tcp [new Agent/TCP]
$ns attach-agent $n(1) $tcp
set ftp [new Application/FTP]
$ftp attach-agent $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n(3) $sink
$ns connect $tcp $sink
$ns at 0.0 "destination"
$ns at 1.0 "$ftp start"
$ns at 100 "finish"
$ns run
