from pathlib import Path
import tempfile, subprocess
s=(Path(__file__).resolve().parents[1] / 'linux/setup.sh').read_text()
# Execute actual dispatcher with isolated HOME and harmless fake child setups.
loop=s[s.index('# Traverse all setup.sh.'):]
with tempfile.TemporaryDirectory() as tmp:
 p=Path(tmp); lib=p/'lib';lib.mkdir()
 for name in ['dotfiles','nvim','bin','agent-workspace','local-llm','local-image-gen']:
  d=lib/name;d.mkdir();(d/'setup.sh').write_text('echo CHILD:'+name+'\n')
 (p/'llm').mkdir();(p/'llm/setup.sh').write_text('echo EXISTING_LLM\n')
 pre='HOME='+tmp+'\nLIB_DIRECTORY='+str(lib)+'\nAppsToSetup=(dotfiles nvim bin agent-workspace local-llm local-image-gen)\nHEALTH_FAILURES=0\nCheckApp() { :; }\nLogFailure() { echo FAIL; }\n'
 confirm=s[s.index('function GetConfirmation()'):s.index('# ネットワーク設定')]
 for answers, expected in [('n\nn\nn\nn\nn\nn\n',False),('n\nn\nn\nn\ny\ny\n',True)]:
  result=subprocess.run(['bash','-c',pre+confirm+loop],input=answers,text=True,capture_output=True)
  assert result.returncode==0,result.stderr
  assert ('EXISTING_LLM' in result.stdout)==expected
  assert ('CHILD:local-image-gen' in result.stdout)==expected
 print('PASS: n skips children; y invokes existing local-llm and image-gen child setup')
