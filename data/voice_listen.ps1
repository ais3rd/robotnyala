# Speech helper for Robot Nyala. The game starts it hidden; it listens on the default
# microphone with Windows' built-in offline recognizer, restricted to the game's command
# phrases, and appends each recognized phrase as a line to -Out. Lines starting with '#'
# are status: '#ready' or '#error <message>'. Exits when the game (-ParentPid) is gone.
param([string]$Out, [string]$Phrases, [int]$ParentPid)

function Say-Line([string]$Text) { Add-Content -Path $Out -Value $Text -Encoding ASCII }

try {
  Add-Type -AssemblyName System.Speech
  $engine = New-Object System.Speech.Recognition.SpeechRecognitionEngine ([System.Globalization.CultureInfo]'en-US')
  $engine.SetInputToDefaultAudioDevice()
  $choices = New-Object System.Speech.Recognition.Choices
  $choices.Add([string[]]($Phrases -split '\|'))
  $builder = New-Object System.Speech.Recognition.GrammarBuilder $choices
  $builder.Culture = $engine.RecognizerInfo.Culture
  $engine.LoadGrammar((New-Object System.Speech.Recognition.Grammar $builder))
  Say-Line '#ready'
  while (Get-Process -Id $ParentPid -ErrorAction SilentlyContinue) {
    $result = $engine.Recognize([TimeSpan]::FromSeconds(2))
    if ($result -and $result.Confidence -ge 0.6) { Say-Line $result.Text }
  }
} catch {
  Say-Line ('#error ' + $_.Exception.Message)
}
