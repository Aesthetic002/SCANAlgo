# 🔧 Installing Icarus Verilog on Windows

**If you prefer to run simulations locally**, follow this guide.

---

## 📥 Quick Installation (5 minutes)

### Step 1: Download Installer

**Official Website:** http://bleyer.org/icarus/

**Direct Download:**
1. Go to: http://bleyer.org/icarus/
2. Click **"iverilog-v12-20220611-x64_setup.exe"** (or latest version)
3. File size: ~50 MB
4. Save to Downloads folder

**Alternative Mirror:**
- SourceForge: https://sourceforge.net/projects/iverilog/

### Step 2: Run Installer

1. Double-click downloaded `.exe` file
2. Click "Yes" if Windows asks for permission
3. Click "Next" on welcome screen
4. **IMPORTANT:** Note the installation path
   - Default: `C:\iverilog`
   - Remember this location!

### Step 3: Installation Options

1. **Select Components:**
   - ✅ Check "Icarus Verilog" (core)
   - ✅ Check "GTKWave" (waveform viewer)
   - ✅ Check "Add to PATH" ← **IMPORTANT!**

2. Click "Next"
3. Choose install location (default is fine)
4. Click "Install"
5. Wait 2-3 minutes
6. Click "Finish"

### Step 4: Add to PATH (If Not Auto-Added)

**If installer didn't add to PATH automatically:**

1. Press `Win + X`
2. Click "System"
3. Click "Advanced system settings" (right side)
4. Click "Environment Variables" (bottom)
5. Under "System variables", find "Path"
6. Click "Edit"
7. Click "New"
8. Add: `C:\iverilog\bin` (or your install path)
9. Click "OK" on all windows

### Step 5: Verify Installation

**Open NEW PowerShell window:**
```powershell
# Close old PowerShell and open new one
# Then test:
iverilog -v
```

**Expected Output:**
```
Icarus Verilog version 12.0 (stable)
...
```

**If you see version info → Success! ✅**

---

## 🚀 Now Run Your Simulation

```powershell
cd D:\ADLD_EL
.\run_sim.bat
```

**Should see:**
```
✓ Compilation successful
✓ Simulation completed
*** ALL TESTS PASSED! *** ✓
```

---

## 🌊 Installing GTKWave (Waveform Viewer)

**Usually included with Icarus Verilog installer!**

### Test if GTKWave Installed:
```powershell
gtkwave
```

If window opens → Already installed! ✅

### If Not Installed Separately:

1. Go to: http://gtkwave.sourceforge.net/
2. Download Windows version
3. Install to default location
4. Add to PATH: `C:\Program Files\gtkwave\bin`

### Open Waveforms:
```powershell
gtkwave elevator_waveform.vcd
```

---

## 🐛 Troubleshooting

### Issue 1: "iverilog not recognized" after install

**Solution:**
1. Make sure you opened **NEW** PowerShell (close old one)
2. Check PATH was updated
3. Reboot computer if needed
4. Verify installation path exists

### Issue 2: Installation fails

**Solution:**
1. Run installer as Administrator
   - Right-click → "Run as administrator"
2. Disable antivirus temporarily
3. Check you have write permissions
4. Try alternative download mirror

### Issue 3: GTKWave not included

**Solution:**
1. Download standalone: http://gtkwave.sourceforge.net/
2. Or use online waveform viewer: https://vc.drom.io/

### Issue 4: DLL errors

**Solution:**
1. Install Visual C++ Redistributable
   - Download from Microsoft
   - Both x86 and x64 versions
2. Reboot after installing

---

## 📊 System Requirements

- **OS:** Windows 7/8/10/11 (64-bit recommended)
- **Disk Space:** ~100 MB
- **RAM:** 2 GB minimum (4 GB recommended)
- **Internet:** Only for download (not for running)

---

## 🎯 Quick Reference

### Compile:
```powershell
iverilog -o output.vvp design.v testbench.v
```

### Simulate:
```powershell
vvp output.vvp
```

### View Waveforms:
```powershell
gtkwave waveform.vcd
```

### All in One (Your Project):
```powershell
.\run_sim.bat
```

---

## ✅ Verification Checklist

After installation:
- [ ] `iverilog -v` shows version
- [ ] `vvp -v` shows version
- [ ] `gtkwave` opens window
- [ ] PATH includes iverilog\bin
- [ ] Can compile .v files
- [ ] Can run simulations
- [ ] Can view waveforms

---

## 🔄 Alternative: Use Chocolatey (Advanced)

**If you have Chocolatey package manager:**

```powershell
# Install Chocolatey first (if not installed)
# Then:
choco install iverilog
choco install gtkwave
```

Automatically handles PATH!

---

## 📚 After Installation

1. **Test with your project:**
   ```powershell
   cd D:\ADLD_EL
   .\run_sim.bat
   ```

2. **All tests should pass!**

3. **View waveforms:**
   ```powershell
   gtkwave elevator_waveform.vcd
   ```

---

## 💡 Pro Tips

1. **Keep installer** - Save .exe for future reinstalls
2. **Update PATH** - Reboot if PATH changes don't work
3. **New terminal** - Always open new PowerShell after install
4. **Check version** - `iverilog -v` to verify

---

## 🌐 Don't Want to Install?

**Use online simulation instead!**

See: `ONLINE_SIMULATION_GUIDE.md`
- No installation needed
- Works immediately
- Just as valid for your project

---

## 📞 Need Help?

**Official Docs:** http://iverilog.icarus.com/  
**Community:** https://github.com/steveicarus/iverilog  
**Tutorials:** YouTube "Icarus Verilog installation"  

---

**Choose your path:**
- 🌐 **Quick:** Use EDA Playground (no install)
- 🔧 **Local:** Install Icarus Verilog (5 min setup)

**Both are perfectly valid for your project! 🚀**
