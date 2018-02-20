var prevTraceTime = 0;
var frameRates = [];


function attachToAddress(address) {
    Interceptor.attach(address, { onEnter: captureFrameRate });
}

function captureFrameRate(args) {
    var currentTraceTime = Date.now();
    if (prevTraceTime) {
        frameRates.push(currentTraceTime - prevTraceTime);
    }
    prevTraceTime = currentTraceTime
}

function traceOpenGL() {
    var flushDrawableAddress = Module.findExportByName('OpenGL', 'CGLFlushDrawable');
    if (flushDrawableAddress) {
        attachToAddress(flushDrawableAddress);
    }
}

function traceMetal() {
    var resolver = new ApiResolver('objc');
    resolver.enumerateMatches('-[CAMetalLayer nextDrawable]', {
        onMatch: function(match) {
            attachToAddress(match.address);
        },
        onComplete: function() {}
    });
}

function processFrameRates() {
    var currentFrameRates = frameRates.splice(0,frameRates.length);
    if (currentFrameRates.length == 0) { return; }
    var asNanoseconds = []
    for (var i=0;i<currentFrameRates.length;i++) {
        asNanoseconds.push(currentFrameRates[i] * 1000000)
    }
    send(asNanoseconds)
}



if (ObjC.available) {
    traceMetal();
    traceOpenGL();
    var samplingRate = options && options.samplingRate ? options.samplingRate : 1000
    setInterval(processFrameRates, samplingRate);
} else {
    send('ObjC runtime is not available');
}
