# Migrate ATA to MDI

For now this is just a quick script to install the Microsoft Defender for Identity on Windows Server Core. When done, it will also remove the old Microsoft Advanced Threat Analytics sensor if that is present.

# To-Do:
  - Configure Directory Services Advanced Auditing events according to the guidance as described in https://aka.ms/mdi/advancedaudit  
    eg: Descendant Computer Objects (Schema-Id-Guid: bf967a86-0de6-11d0-a285-00aa003049e2)  
      
   - Configure the Directory Services Object Auditing events according to the guidance as described in https://aka.ms/mdi/objectauditing    
