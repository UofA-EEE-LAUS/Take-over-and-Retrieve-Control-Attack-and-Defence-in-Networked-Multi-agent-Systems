# TAKE-OVER-AND-RETRIEVE-CONTROL-ATTACK-AND-DEFENCE-IN-NETWORKED-MULTI-AGENT-SYSTEMS
## University of Adelaide FYP 7331 2020 s2

### Software Environment: 
* Windows 10
* MATLAB R2020a
* CoppeliaSim 4.1
* Python 3.7
* Wireshark 3.4.6

### Python Package: 
* Scapy: pip install scapy

### Steps: 
* Launch CoppeliaSim with *V-REP/agent_test.ttt*
* Launch the agent process in MATLAB (*MATLAB/area_scanning_agent.m* without defence or *MATLAB/area_scanning_agent_defense.m* with defence)
* Start an attack if needed from *PYTHON/*.py* (need to change current working directory to use the sample pcap files)
* Launch the host process in MATLAB (*MATLAB/area_scanning_host.m* without defence or *MATLAB/area_scanning_host_defense.m* with defence)
* Wait for the scanning to complete. If not stopping automatically, shut the *agent process* by pressing Ctrl+C in MATLAB's command window. 
* The host process should stop 10s after the agent process is finished. Scanning results and packet statistics should be shown. 
