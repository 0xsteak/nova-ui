import sys
import subprocess
import shutil
import os
from pathlib import Path

convertType = sys.argv[1] if len(sys.argv) > 1 else None
srcPath = sys.argv[2] if len(sys.argv) > 2 else None
convertedPath = sys.argv[3] if len(sys.argv) > 3 else None

# Convert string requires to roblox requires
def rblx_require(path: str, destination: str):
    # Clean if exists
    for filename in os.listdir(destination):
        file_path = os.path.join(destination, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print('Failed to delete %s. Reason: %s' % (file_path, e))
            
    # Create path if it doesnt exist
    Path(destination).mkdir(parents=True, exist_ok=True)
    
    # Convert
    darkluaConfig = "darklua/convert-require.json5"
    output = subprocess.run(["darklua", "process", "-c", darkluaConfig, path, destination], capture_output=True, text=True)
    if output.stdout:
        print(output.stdout)
    if output.stderr:
        print(output.stderr)
    print(f"[rblx_require] converted to {destination} sucessfully")
    
# Remove @self aliases, bc darklua doesnt support them yet
def remove_self(path: str, destination: str):
    # Remove if exists
    if os.path.exists(destination):
        shutil.rmtree(destination)
        
    # Create path if it doesnt exist
    Path(destination).mkdir(parents=True, exist_ok=True)
    
    # Replacing
    for subdir, _, files in os.walk(path):
        for fileName in files:
            filePath = os.path.join(subdir, fileName)
            newFilePath = os.path.join(destination, os.path.relpath(filePath, path))
            
            Path(os.path.dirname(newFilePath)).mkdir(parents=True, exist_ok=True)
            
            with open(filePath) as file:
                newContent = file.read().replace('require("@self', 'require(".')
                with open(newFilePath, "w") as newFile:
                    newFile.write(newContent)
                
    print(f"[remove_self] converted to {destination} successfully")
            
if __name__ == "__main__":
    match convertType:
        case "rblx_require":
            # Convert self requires to temp-src folder
            remove_self(srcPath, "temp-src")
            
            # Create sourcemap for darklua require convert
            output = subprocess.run(["rojo", "sourcemap", "temp.project.json", "-o", "temp-sourcemap.json"])
            if output.stdout:
                print(output.stdout)
            if output.stderr:
                print(output.stderr)
            
            rblx_require("temp-src", convertedPath)
            
            # Remove temp-src folder
            shutil.rmtree("temp-src")
        case "remove_self":
            remove_self(srcPath, convertedPath)
        case _:
            print("Invalid convert type")