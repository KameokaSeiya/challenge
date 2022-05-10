
if (WScript.Arguments.length > 0) {
    var shell = WScript.CreateObject('WScript.Shell');
    try {
        shell.Run(WScript.Arguments(0))
    } catch (err) {

    }
}
