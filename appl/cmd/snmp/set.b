implement SnmpSet;

include "sys.m";
	sys: Sys;
	sprint: import sys;
include "draw.m";
include "arg.m";
include "lists.m";
	lists: Lists;
include "snmp.m";
	snmp: Snmp;
	Val: import snmp;
include "snmpclient.m";
	snmpclient: Snmpclient;
	Snmpc: import snmpclient;

SnmpSet: module {
	init:	fn(nil: ref Draw->Context, args: list of string);
};


dflag: int;

init(nil: ref Draw->Context, args: list of string)
{
	sys = load Sys Sys->PATH;
	arg := load Arg Arg->PATH;
	lists = load Lists Lists->PATH;
	snmp = load Snmp Snmp->PATH;
	snmp->init();
	snmpclient = load Snmpclient Snmpclient->PATH;
	snmpclient->init();

	s := Snmpc.new();
	arg->init(args);
	arg->setusage(arg->progname()+" [-d] "+snmpclient->usage+" addr oid value ... ...");
	while((c := arg->opt()) != 0)
		case c {
		'd' =>	snmp->dflag = dflag++;
		* =>	s.setopt(c, arg);
		}
	args = arg->argv();
	if(len args < 3)
		arg->usage();
	s.addr = hd args;
	args = tl args;
	if(len args % 2 != 0)
		arg->usage();

	l, r: list of ref (string, ref Val);
	for(; args != nil; args = tl tl args) {
		(val, err) := Val.parse(hd tl args);
		if(err != nil)
			fail(sprint("parsing %q: %s", hd tl args, err));
		l = ref (hd args, val)::l;
	}
	l = lists->reverse(l);

	err := s.init();
	if(err == nil)
		(r, err) = s.setm(l);
	if(err != nil)
		fail("get: "+err);
	for(; r != nil; r = tl r) {
		(o, v) := *hd l;
		sys->print("%-35s %s\n", o, v.text());
	}
}

fail(s: string)
{
	sys->fprint(sys->fildes(2), "%s\n", s);
	raise "fail:"+s;
}
