param([Parameter(Mandatory=$true)][string]$Manifest)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Speech
Add-Type -ReferencedAssemblies System.Speech -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Speech.Recognition;
using System.Threading;
public static class LocalNarrationSpeech {
 public static List<RecognitionResult> Read(string path) {
  using (var engine = new SpeechRecognitionEngine())
  using (var done = new ManualResetEvent(false)) {
   var results = new List<RecognitionResult>(); Exception error = null;
   engine.LoadGrammar(new DictationGrammar()); engine.SetInputToWaveFile(path);
   engine.SpeechRecognized += (s,e) => results.Add(e.Result);
   engine.RecognizeCompleted += (s,e) => { error=e.Error; done.Set(); };
   engine.RecognizeAsync(RecognizeMode.Multiple);
   if (!done.WaitOne(90000)) { engine.RecognizeAsyncCancel(); throw new TimeoutException("Offline recognition timed out."); }
   if (error != null) throw error;
   return results;
  }
 }
}
'@
$clips=Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
$folder=Split-Path -Parent $Manifest
$archive=Split-Path -Parent (Split-Path -Parent $folder)
$utterances=New-Object System.Collections.Generic.List[object]
 foreach ($clip in $clips) {
  foreach ($spoken in [LocalNarrationSpeech]::Read((Join-Path $archive $clip.file))) {
   $utterances.Add([pscustomobject]@{text=$spoken.Text;confidence=$spoken.Confidence;file=$clip.file;
    start_ms=([long]$clip.start_ms+[long]$spoken.Audio.AudioPosition.TotalMilliseconds);
    duration_seconds=$spoken.Audio.Duration.TotalSeconds})
  }
 }
 $json=ConvertTo-Json -InputObject @($utterances.ToArray()) -Depth 4
 [IO.File]::WriteAllText((Join-Path $folder 'transcript.json'),$json,(New-Object Text.UTF8Encoding($false)))
