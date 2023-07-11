set ns [new Simulator]
set f_ [ open red.tr w ]
$ns trace-all $f_ 
set nf [ open red.nam w ]
$ns namtrace-all $nf    
set node_(s1) [$ns node]
set node_(s5) [$ns node]
set node_(s2) [$ns node]
set node_(r1) [$ns node]
set node_(r2) [$ns node]
set node_(s3) [$ns node]
set node_(s4) [$ns node]
set node_(s6) [$ns node]
Queue/RED set thresh_ 5
Queue/RED set maxthresh_ 45
Queue/RED set bytes_ false
Queue/RED set queue_in_bytes_ false
Queue/RED set linterm_ 1
Queue/RED set q_weight_ 0.02
Queue/RED set drop_tail_ true
Queue/RED set setbit true 
$ns duplex-link $node_(s1) $node_(r1) 1Mb 2ms DropTail 
$ns duplex-link $node_(s2) $node_(r1) 1Mb 3ms DropTail 
$ns duplex-link $node_(s5) $node_(r1) 1Mb 4ms DropTail 
$ns duplex-link $node_(r1) $node_(r2) 1Mb 45ms RED 
$ns queue-limit $node_(r1) $node_(r2) 25
$ns queue-limit $node_(r2) $node_(r1) 25
$ns duplex-link $node_(s3) $node_(r2) 10Mb 4ms DropTail 
$ns duplex-link $node_(s4) $node_(r2) 10Mb 5ms DropTail 
$ns duplex-link $node_(s6) $node_(r2) 10Mb 4ms DropTail 

$ns duplex-link-op $node_(s1) $node_(r1) orient right-down
$ns duplex-link-op $node_(s2) $node_(r1) orient right-up
$ns duplex-link-op $node_(s5) $node_(r1) orient right
$ns duplex-link-op $node_(r1) $node_(r2) orient right
$ns duplex-link-op $node_(r1) $node_(r2) queuePos 0
$ns duplex-link-op $node_(r2) $node_(r1) queuePos 0
$ns duplex-link-op $node_(s3) $node_(r2) orient left-down
$ns duplex-link-op $node_(s4) $node_(r2) orient left-up
$ns duplex-link-op $node_(s6) $node_(r2) orient left
#set cbr [new Application/Traffic/CBR]
$ns color 0 RED
set tcp1 [$ns create-connection TCP/Reno $node_(s1) TCPSink $node_(s3) 0]
$tcp1 set window_ 64
set tcp2 [$ns create-connection TCP/Reno $node_(s2) TCPSink $node_(s3) 1]
$tcp2 set window_ 64
$tcp2 set packetSize_ 576
$tcp1 set packetSize_ 576
set ftp1 [$tcp1 attach-source FTP]
set ftp2 [$tcp2 attach-source FTP]
set redq [[$ns link $node_(r1) $node_(r2)] queue]
set tchan_ [open all.q w]
#$cbr attach-agent $tcp1
#$cbr set packet_size_ 576
$redq trace curq_
$redq trace ave_
$redq attach $tchan_


$ns at 0.0 "$ftp1 start"
$ns at 3.0 "$ftp2 start"
$ns at 10 "finish"

# Define 'finish' procedure (include post-simulation processes)
proc finish {} {
    global tchan_
    set awkCode {
	{
	    if ($1 == "Q" && NF>2) {
		print $2, $3>> "temp.q";
		set end $2
	    }
	    else if ($1 == "a" && NF>2)
	    print $2, $3 >> "temp.a";
	}
    }
    set f [open temp.queue w]
    puts $f "TitleText: red"
    puts $f "Device: Postscript"
    
    if { [info exists tchan_] } {
	close $tchan_
    }
    exec rm -f temp.q temp.a 
    exec touch temp.a temp.q
    exec awk $awkCode all.q
    puts $f "11 13"
    puts $f "12 13"
    puts $f "next\n"
    puts $f \"queue"
    puts $f "anno 9 13 queue\n"
    exec cat temp.q >@ $f 
    # ghi file temp.q vao f
    puts $f "next\n"
    puts $f "color=blue"
    puts $f "11 11"
    puts $f "12 11"
    puts $f "next\n"
    puts $f "color=blue"
    puts $f \n\"ave_queue"
    puts $f "anno 9 11 av_queue\n"
    exec cat temp.a >@ $f
    close $f
    exec nam red.nam &
    exec xgraph temp.queue
    
    exit 0
}

$ns run
