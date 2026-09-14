"The demo call for the panel: it holds the machine, releases it, holds it again, and so on, so you
can see the image struggle and then watch a cancellation bring it back.

Paste it in the code field of print_it and press Run: the panel shows the request id while it runs,
and the Cancel button next to Run stops it. It writes its rounds to the Transcript, so whoever has
the image open sees the counter stop the moment it is cancelled."

| rounds round deadline work report |
rounds := 20.
round := 0.

"Above the UI (50) and above the request handlers (60). This is the line that makes the image feel
frozen on purpose, so there is something to cancel: take it out and the image stays nimble while the
call runs, which is what the worker below the UI buys."
Processor activeProcess priority: 70.

[ round < rounds ] whileTrue: [
	round := round + 1.
	Transcript show: 'round ', round printString, ' of ', rounds printString, ': holding the machine, the image feels stuck'; newLine.
	deadline := Time millisecondClockValue + 1000.
	work := 1.0.
	"work is here so that the loop cannot be folded away by the compiler"
	[ Time millisecondClockValue < deadline ] whileTrue: [ work := work + 1.0 ].
	Transcript show: 'round ', round printString, ': released for two seconds, and this is the window a cancellation gets in through'; newLine.
	(Delay forSeconds: 2) wait ].

report := WriteStream on: String new.
report nextPutAll: 'finished '; print: round; nextPutAll: ' rounds without being cancelled'.
report contents
