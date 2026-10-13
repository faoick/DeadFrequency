from pathlib import Path
import json,re,zipfile,shutil

ROOT=Path(__file__).resolve().parents[1]
def read(p):return json.loads(re.sub(r',\s*([}\]])',r'\1',p.read_text(encoding='utf8')))
def write(p,obj):
    p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=False,indent=2,sort_keys=True),encoding='utf8')
def ref(name,path):return {'name':name,'path':path}
with zipfile.ZipFile('C:/Program Files/GameMaker-LTS2026/ProjectTemplates/new_blank/new_blank.yyz') as template:
    project=json.loads(re.sub(r',\s*([}\]])',r'\1',template.read('new_blank.yyp').decode('utf8')))
project['name']=project['%Name']='DeadFrequency';project['MetaData']={'IDEVersion':'2026.0.0.16'}
project['resources']=[]
def add(name,path):project['resources'].append({'id':ref(name,path)})
parent=ref('DeadFrequency','DeadFrequency.yyp')
obj={'$GMObject':'','%Name':'obj_game','name':'obj_game','resourceType':'GMObject','resourceVersion':'2.0',
     'eventList':[], 'managed':True,'overriddenProperties':[],'parent':parent,'parentObjectId':None,'persistent':False,
     'physicsAngularDamping':.1,'physicsDensity':.5,'physicsFriction':.2,'physicsGroup':1,'physicsKinematic':False,
     'physicsLinearDamping':.1,'physicsObject':False,'physicsRestitution':.1,'physicsSensor':False,'physicsShape':1,
     'physicsShapePoints':[],'physicsStartAwake':True,'properties':[],'solid':False,'spriteId':None,'spriteMaskId':None,'visible':True}
for typ,num in [(0,0),(3,0),(8,0),(8,64),(12,0)]:obj['eventList'].append({'$GMEvent':'v1','%Name':'','name':'','eventType':typ,'eventNum':num,'isDnD':False,'collisionObjectId':None,'resourceType':'GMEvent','resourceVersion':'2.0'})
write(ROOT/'objects/obj_game/obj_game.yy',obj);add('obj_game','objects/obj_game/obj_game.yy')
for script in ['scr_game','scr_tests','scr_campaign','scr_action','scr_hub','scr_perf']:
    write(ROOT/f'scripts/{script}/{script}.yy',{'$GMScript':'v1','%Name':script,'name':script,'isCompatibility':False,'isDnD':False,'parent':parent,'resourceType':'GMScript','resourceVersion':'2.0'})
    add(script,f'scripts/{script}/{script}.yy')
room=read(ROOT/'rooms/Room1/Room1.yy');room['parent']=parent;room['roomSettings']['Width']=960;room['roomSettings']['Height']=640
instance={'$GMRInstance':'v1','%Name':'inst_game','name':'inst_game','colour':4294967295,'hasCreationCode':False,'frozen':False,
          'ignore':False,'imageIndex':0,'imageSpeed':1,'inheritCode':False,'inheritedItemId':None,'inheritItemSettings':False,'isDnd':False,
          'objectId':ref('obj_game','objects/obj_game/obj_game.yy'),'properties':[],'resourceType':'GMRInstance','resourceVersion':'2.0',
          'rotation':0,'scaleX':1,'scaleY':1,'x':0,'y':0}
room['layers'][0]['instances']=[instance];room['instanceCreationOrder']=[ref('inst_game','rooms/Room1/Room1.yy')]
room['viewSettings']['enableViews']=True
room['views'][0].update({'visible':True,'wview':640,'hview':360,'wport':960,'hport':540})
write(ROOT/'rooms/Room1/Room1.yy',room);add('Room1','rooms/Room1/Room1.yy')
for wav in (ROOT/'datafiles').glob('*.wav'):
    import shutil
    name='snd_'+wav.stem;p=ROOT/f'sounds/{name}';p.mkdir(parents=True,exist_ok=True);shutil.copyfile(wav,p/(name+'.wav'))
    sound={'$GMSound':'v2','%Name':name,'name':name,'audioGroupId':ref('audiogroup_default','audiogroups/audiogroup_default'),
           'bitDepth':1,'channelFormat':0,'compression':0,'compressionQuality':4,'conversionMode':0,'duration':0,'exportDir':'','parent':parent,
           'preload':True,'resourceType':'GMSound','resourceVersion':'2.0','sampleRate':22050,'soundFile':name+'.wav','volume':1.0}
    write(p/(name+'.yy'),sound);add(name,f'sounds/{name}/{name}.yy')
for license in (ROOT/'licenses').glob('*.txt'):shutil.copyfile(license,ROOT/'datafiles'/license.name)
shutil.copyfile(ROOT/'README.md',ROOT/'datafiles/README.txt')
project['IncludedFiles']=[{'$GMIncludedFile':'','%Name':f.name,'name':f.name,'CopyToMask':-1,'filePath':'datafiles','resourceType':'GMIncludedFile','resourceVersion':'2.0'} for f in (ROOT/'datafiles').iterdir() if f.suffix in ['.png','.json','.ttf','.txt']]
write(ROOT/'DeadFrequency.yyp',project)
write(ROOT/'DeadFrequency.resource_order',{'FolderOrderSettings':[],'ResourceOrderSettings':[]})
write(ROOT/'tools/windows-options.reference.json',{
 '$GMWindowsOptions':'','%Name':'Windows','name':'Windows','resourceType':'GMWindowsOptions','resourceVersion':'2.0',
 'option_windows_display_name':'DEAD FREQUENCY','option_windows_executable_name':'DeadFrequency',
 'option_windows_version':'1.0.0.0','option_windows_company_info':'Dead Frequency','option_windows_copyright_info':'Original game assets 2026',
 'option_windows_description_info':'DEAD FREQUENCY - midnight top-down action','option_windows_product_info':'DEAD FREQUENCY',
 'option_windows_copy_exe_to_dest':False,'option_windows_start_fullscreen':False,'option_windows_allow_fullscreen_switching':True,'option_windows_interpolate_pixels':False,
 'option_windows_vsync':True,'option_windows_resize_window':True,'option_windows_borderless':False,'option_windows_scale':0,
 'option_windows_display_cursor':True,'option_windows_sizeable':True,'option_windows_enable_steam':False,
 'option_windows_disable_sandbox':False,'option_windows_texture_page':'2048x2048',
 'option_windows_icon':'${base_options_dir}/windows/icons/icon.ico','option_windows_splash_screen':'${base_options_dir}/windows/splash/splash.png',
 'option_windows_installer_finished':'${base_options_dir}/windows/installer/finished.bmp',
 'option_windows_installer_header':'${base_options_dir}/windows/installer/header.bmp',
 'option_windows_license':'${base_options_dir}/windows/installer/license.txt',
 'option_windows_nsis_file':'${base_options_dir}/windows/installer/nsis_script.nsi',
 'option_windows_save_location':0,'option_windows_sleep_margin':10,'option_windows_software_vertex_processing':False,
 'option_windows_steam_use_alternative_launcher':False,'option_windows_steam_app_id':'','option_windows_use_splash':False,
 'option_windows_vertex_method':1,'option_windows_alternate_sync_method':False,'option_windows_create_textures_on_demand':False})
print('Project manifest generated:',ROOT/'DeadFrequency.yyp')
