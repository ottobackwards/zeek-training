# run_cmd: zeek -C -r pcaps/ssh-over-443.pcap  policy/frameworks/dpd/detect-protocols.zeek 

@load policy/frameworks/dpd/detect-protocols.zeek

module XmasTree ; 

# ACTION: uncomment below this for notice suppression
#redef Notice::ignored_types += { ProtocolDetector::Protocol_Found, } ; 


event zeek_init()
    {
    	print fmt ("in the script look for: "); 
	    print fmt ("ACTION: uncomment below this for notice suppression"); 
        print fmt ("look into notice.log before and after uncommenting");
        print fmt ("");
        print fmt ("");
        print fmt ("=========================");
    }

export {

	redef enum Notice::Type += {
                Lights, 
        };

	global expire_notice_escalation: function(t: table[addr] of set[Notice::Type], idx: addr): interval ; 

	global notice_escalation: table[addr] of set[Notice::Type] &create_expire=10 secs &expire_func=expire_notice_escalation ; 

} 

redef Notice::alarmed_types += { XmasTree::Lights}; 


function expire_notice_escalation (t: table[addr] of set[Notice::Type], idx: addr): interval 
    { 
	print fmt ("%s", t); 

	return 0 secs; 
    } 

hook Notice::policy(n: Notice::Info)
    {
	if (!n?$id) 
		return ; 
		
	local ip=n$id$orig_h ; 

	#local ip=n$src ;  // determine why is that wrong :) 

    if ( ip !in notice_escalation) { 	
		local aset: set[Notice::Type] ; 
		notice_escalation[ip]=aset ; 
	} 
                
	add notice_escalation[ip] [n$note] ; 

	if (|notice_escalation[ip]| > 1) { 
		local _msg = fmt ("Many notices from %s", ip); 

		for (a in notice_escalation[ip]) 
			_msg += fmt (" %s ", a) ; 
	
		NOTICE([$note=Lights, $identifier=cat(ip), $suppress_for=1 hrs, $msg=_msg]);
	} 
        
}
