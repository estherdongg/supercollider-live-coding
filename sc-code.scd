// Esther Dong, December 2024

 _____     _   _                 ____         _     _              ____          _ _
 | ____|___| |_| |__   ___ _ __  |  _ \       | |   (_)_   _____   / ___|___   __| (_)_ __   __ _
 |  _| / __| __| '_ \ / _ \ '__| | | | |      | |   | \ \ / / _ \ | |   / _ \ / _` | | '_ \ / _` |
 | |___\__ \ |_| | | |  __/ |    | |_| |  _   | |___| |\ V /  __/ | |__| (_) | (_| | | | | | (_| |
 |_____|___/\__|_| |_|\___|_|    |____/  (_)  |_____|_| \_/ \___|  \____\___/ \__,_|_|_| |_|\__, |
                                                                                            |___/


// initialize the Clock
(
var maxNumBus = s.options.numControlBusChannels;
var maxDivision = 96;
var f = {
    ~clock = { |bpm = 60|
        var tick = Impulse.kr(bpm/60*maxDivision);
        var count = PulseCount.kr(tick);
        Out.kr(maxNumBus-1, count);
    }.play;
    "Clock initialized.".postln;
};
f.();

ServerTree.removeAll;
ServerTree.add(f,s);
~tg = {|div|
	  Trig1.kr(((In.kr(maxNumBus-1) % (maxDivision / div)).floor < 1),0.01);
};
~tc = {|div|
      (In.kr(maxNumBus-1) / (maxDivision / div)).floor;
};
~gate = {|div,n,seqs|
    Mix(seqs.collect({|c| (~tc.(div) % n).floor eq: c}) * ~tg.(div));
};
)

// =========================================================================================================

s.meter.alwaysOnTop_(true);  // OPTIONAL unless you want the meter window be open
~clock.set(\bpm,70);  // tempo setting
({GVerb.ar(In.ar(16,2),110,6.0)}.play(target:0,addAction:\addToTail));

// =========================================================================================================

//bass 1
Ndef(\bass1).fadeTime_(5).play; // optional editing the fadeTime
Ndef(\bass1, {
    var gate = ~tg.(4); // trigger signal at 1 Hz
    var note = 55; // midi note for the bass
    Pan2.ar(
        SinOsc.ar(note.midicps, 0.0, EnvGen.kr(Env.perc(0.0, 0.5), gate)) * 0.5
    );
});

// =========================================================================================================


//bass 2
Ndef(\bass2).fadeTime_(2).play; // optional editing the fadeTime
Ndef(\bass2, {
    var gate = ~tg.(4); // trigger signal at 1 Hz
    var note = TChoose.kr(gate,[40,44,48,52,56]); // midi note for the bass
	Pan2.ar(PMOsc.ar(note.midicps,note.midicps*0.5, TIRand.kr(1,8,gate), 0.0, EnvGen.kr(Env.perc(0.0, 0.5), gate))) * 0.2;
}) //


// =========================================================================================================


//arp
Ndef(\arp).fadeTime_(2).playN(outs: [0, 1, 16, 17], amps:[0.2,0.2,0.2,0.2]); // optional editing the fadeTime/amps
Ndef(\arp, {
    var gate = ~tg.(4); // trigger signal at 1 Hz
	var note = TChoose.kr(gate,[56,60,64,68,72,78])+12; // midi note for the arp
	Pan2.ar(PMOsc.ar(note.midicps,note.midicps*0.5*TIRand.kr(1,4,gate),TIRand.kr(1,4,gate), 0.0, EnvGen.kr(Env.perc(0.0, 0.5), gate)),TRand.kr(0.1, 0.8, gate)
	)*0.2;
})


// =========================================================================================================


//pad
Ndef(\pad).fadeTime_(2).playN(outs: [0, 1, 16, 17], amps:[0.1,0.1,0.1,0.1]); // optional editing the fadeTime/amps
Ndef(\pad, {
    var gate = ~tg.(1); // trigger signal at 1 Hz
	var note = Select.kr({|idx| ((~tc.(4) / 64).floor % 2 *4+idx)}.dup(4),[48,52,56,60,64,68,72]); // midi note for the choed
    PMOsc.ar([note.midicps,note.midicps+4],note.dup(2).midicps,1.4,0.0, EnvGen.kr(Env.new([0.0,1.0,0.0],[1.5,2.5]),gate)).collect({|sig|Mix(sig)})*0.1;
})


// =========================================================================================================


//lead
Ndef(\lead).fadeTime_(2).playN(outs: [0, 1, 16, 17], amps:[0.3,0.3,0.2,0.2]);
Ndef(\lead, {
    var gate = ~tg.(0.25);
	var note = VarLag.kr(TChoose.kr(gate,[52,56,60,64,68,78])+12, 0.6); // VarLag.kr(input, time, curv = 0, warp = 5, start = 0, gate = 1) optional editing those paremeters: input midi notes; lag time; curv (optional); warp (optional); start (optional); gate (optional) // adds 12 to transpose the notes up an octave

    Pan2.ar(Mix(Saw.ar([note,note+7].midicps, 0.4)))*0.5;
})


// =========================================================================================================

//drums
Ndef(\drums, {
	var envperc = {|dec,gate| EnvGen.kr(Env.perc(0.0,dec),gate)};
    var hh_g = ~tg.(8);// trigger signal at 1 Hz
	var hh = WhiteNoise.ar(envperc.(0.1,hh_g))*0.3*~tc.(16).sin;
	var kk_g = ~gate.(4,16,[0,6,16,19,22]);
	var kick =PMOsc.ar(40,110*envperc.(0.08,kk_g),8.0,0,envperc.(0.2,kk_g))*0.8;
	var sn_g = ~gate.(4,16,[8]);
	var sn = BPF.ar(WhiteNoise.ar, envperc.(0.1,sn_g)*880+440)* envperc.(0.2,sn_g)*1.0;
	Out.ar(16,[sn,sn]*0.3);
	Pan2.ar(hh+kick+sn);
}).play;


// =========================================================================================================

// release the each section by changing the fadeTime of the release
(
[\bass2].do({| synth|
	Ndef(synth).fadeTime_(5).release;
});
)


