import sys, os
from upyrc import upyre
def main():
    # if len(sys.argv)!=2:print("Usage: python unreal-remote.py path-to-script");return 1
    script_path = os.path.abspath(sys.argv[1])
    config=upyre.RemoteExecutionConfig(multicast_group=("239.0.0.1",6766),multicast_bind_address="127.0.0.1")
    try:
        with upyre.PythonRemoteConnection(config) as conn:
            # print(f"Executing Python script: {script_path}")
            result=conn.execute_python_command(script_path,exec_type=upyre.ExecTypes.EXECUTE_FILE,raise_exc=True)
            # print("Command execution result:");
            print(result)
            # if hasattr(result,'output')and result.output:print("Output from Unreal Engine:");print(result.output)
    except Exception as e:print(f"Error: {e}");return 1
    return 0
if __name__=="__main__":sys.exit(main())

