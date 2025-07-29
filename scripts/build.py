import os
import zipfile
import sys
import subprocess
import convert_source
import shutil

buildType = sys.argv[1] if len(sys.argv) > 1 else None

src = "src"
rblxSrc = "rblx-src"
outDir = "dist"

if not os.path.exists(outDir):
    os.mkdir(outDir)

def source(fileName: str):
    zipPath = os.path.join(outDir, fileName)
    
    if os.path.exists(zipPath):
        os.remove(zipPath)
    
    with zipfile.ZipFile(zipPath, "w", zipfile.ZIP_DEFLATED) as archive:
        for root, _, files in os.walk(src):
            for file in files:
                path = os.path.join(root, file)
                relPath = os.path.relpath(path, src)
                inZipPath = os.path.join("Nova", relPath)
                archive.write(path, arcname=inZipPath)
    print(f"Archived at '{zipPath}'")
    
def bundle(fileName: str):
    darkluaConfig = "darklua/bundle.json5"
    entryPoint = os.path.join("temp-src", "init.luau")
    out = os.path.join(outDir, fileName)
    
    convert_source.remove_self(src, "temp-src")
    
    output = subprocess.run(["darklua", "process", "-c", darkluaConfig, entryPoint, out], capture_output=True, text=True)
    if output.stdout:
        print(output.stdout)
    if output.stderr:
        print(output.stderr)
        
    shutil.rmtree("temp-src")
    
def rbxm(fileName: str):
    projectFile = "rbxm-build.project.json"
    output = subprocess.run(["rojo", "build", "-o", os.path.join(outDir, fileName), projectFile], capture_output=True, text=True)
    if output.stdout:
        print(output.stdout)
    if output.stderr:
        print(output.stderr)
        
fileName = sys.argv[2] if len(sys.argv) > 2 else None
if not fileName:
    print("File name argument missing")
    sys.exit(1)
                
match buildType:
    case "source":
        source(fileName)
    case "bundle":
        bundle(fileName)
    case "rbxm":
        rbxm(fileName)
    case _:
        print("Build type argument missing")