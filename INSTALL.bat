@echo off
setlocal

:: ============================================================================
::  SIERA PDF - Fast Installer
:: ============================================================================

cd /d "%~dp0"
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"

title SIERA PDF - Installer
echo.
echo   Installing SIERA PDF...
echo.

set "INSTDIR=%ProgramFiles%\SieraPDF"
set "PROGID=SieraPDF.PDF"
set "APPNAME=SIERA PDF"
set "BATPATH=%INSTDIR%\open-pdf.bat"
set "ICOPATH=%INSTDIR%\app.ico"
set "PS1PATH=%INSTDIR%\handler.ps1"

if not exist "%INSTDIR%" mkdir "%INSTDIR%"

:: Write handler.ps1 from embedded base64
set "B64=%TEMP%\siera_h.b64"
(
echo cGFyYW0oW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUsUG9zaXRpb249MCldW3N0cmluZ10kUGRm
echo UGF0aCkKJEVycm9yQWN0aW9uUHJlZmVyZW5jZSA9ICJTdG9wIgoKJGxvZ0ZpbGUgPSBKb2luLVBh
echo dGggKFtTeXN0ZW0uSU8uUGF0aF06OkdldFRlbXBQYXRoKCkpICJTaWVyYVBERi1kZWJ1Zy5sb2ci
echo CmZ1bmN0aW9uIExvZygkbXNnKSB7CiAgICAkdHMgPSBHZXQtRGF0ZSAtRm9ybWF0ICJ5eXl5LU1N
echo LWRkIEhIOm1tOnNzIgogICAgIiR0cyAgJG1zZyIgfCBPdXQtRmlsZSAtQXBwZW5kIC1GaWxlUGF0
echo aCAkbG9nRmlsZSAtRW5jb2RpbmcgVVRGOAp9CgpMb2cgIj09PSBTSUVSQSBQREYgc3RhcnRlZCA9
echo PT0iCkxvZyAiUGRmUGF0aDogJFBkZlBhdGgiCgppZiAoLW5vdCAoVGVzdC1QYXRoIC1MaXRlcmFs
echo UGF0aCAkUGRmUGF0aCkpIHsKICAgIExvZyAiRVJST1I6IEZpbGUgbm90IGZvdW5kIgogICAgQWRk
echo LVR5cGUgLUFzc2VtYmx5TmFtZSBTeXN0ZW0uV2luZG93cy5Gb3JtcwogICAgW1N5c3RlbS5XaW5k
echo b3dzLkZvcm1zLk1lc3NhZ2VCb3hdOjpTaG93KCJGaWxlIG5vdCBmb3VuZDogJFBkZlBhdGgiLCAi
echo U0lFUkEgUERGIiwgIk9LIiwgIkVycm9yIikgfCBPdXQtTnVsbAogICAgZXhpdCAxCn0KCiRQZGZQ
echo YXRoID0gKFJlc29sdmUtUGF0aCAtTGl0ZXJhbFBhdGggJFBkZlBhdGgpLlBhdGgKJE9yaWdpbmFs
echo ID0gW1N5c3RlbS5JTy5QYXRoXTo6R2V0RmlsZU5hbWUoJFBkZlBhdGgpCiRCYXNlID0gW1N5c3Rl
echo bS5JTy5QYXRoXTo6R2V0RmlsZU5hbWVXaXRob3V0RXh0ZW5zaW9uKCRPcmlnaW5hbCkgLXJlcGxh
echo Y2UgJ1teYS16QS1aMC05X1wtXScsICdfJwppZiAoW3N0cmluZ106OklzTnVsbE9yRW1wdHkoJEJh
echo c2UpKSB7ICRCYXNlID0gImRvY3VtZW50IiB9CiRFeHQgPSBbU3lzdGVtLklPLlBhdGhdOjpHZXRF
echo eHRlbnNpb24oJE9yaWdpbmFsKQppZiAoW3N0cmluZ106OklzTnVsbE9yRW1wdHkoJEV4dCkpIHsg
echo JEV4dCA9ICIucGRmIiB9CiRVaWQgPSBbZ3VpZF06Ok5ld0d1aWQoKS5Ub1N0cmluZygiTiIpLlN1
echo YnN0cmluZygwLDgpCiROYW1lID0gIiR7VWlkfV8ke0Jhc2V9JHtFeHR9IgpMb2cgIlVwbG9hZCBh
echo czogJE5hbWUiCgokTWluSU8gPSAiaHR0cDovLzE3Mi4yMC41LjY1OjkwMDAiCiRCdWNrZXQgPSAi
echo cGRmcGx1Z2luIgokVXBsb2FkVXJsID0gIiRNaW5JTy8kQnVja2V0LyROYW1lIgoKdHJ5IHsKICAg
echo IExvZyAiVXBsb2FkaW5nOiAkVXBsb2FkVXJsIgogICAgSW52b2tlLVdlYlJlcXVlc3QgLVVyaSAk
echo VXBsb2FkVXJsIC1NZXRob2QgUFVUIC1JbkZpbGUgJFBkZlBhdGggLUNvbnRlbnRUeXBlICJhcHBs
echo aWNhdGlvbi9wZGYiIC1Vc2VCYXNpY1BhcnNpbmcgLVRpbWVvdXRTZWMgMTIwIHwgT3V0LU51bGwK
echo ICAgIExvZyAiVXBsb2FkIE9LIgoKICAgIEFkZC1UeXBlIC1Bc3NlbWJseU5hbWUgU3lzdGVtLldl
echo YgogICAgJEVuY29kZWQgPSBbU3lzdGVtLldlYi5IdHRwVXRpbGl0eV06OlVybEVuY29kZSgkVXBs
echo b2FkVXJsKQogICAgJFNoYXJlVXJsID0gImh0dHBzOi8vc2hhcmVzdWl0ZS5tdXAtZGlnaXRhbC5j
echo b20vI209Y29yZTphPXBkZi1nZW5lcmF0aW9uLWZyb250ZW5kOnZpZXc9cGRmLWdlbmVyYXRpb24t
echo ZnJvbnRlbmQ6Y3R4SWQ9MjgzNTpwZGZVcmw9JEVuY29kZWQiCiAgICBMb2cgIk9wZW5pbmc6ICRT
echo aGFyZVVybCIKICAgIFN0YXJ0LVByb2Nlc3MgJFNoYXJlVXJsCn0gY2F0Y2ggewogICAgJGVyciA9
echo ICRfLkV4Y2VwdGlvbi5NZXNzYWdlCiAgICBMb2cgIkVSUk9SOiAkZXJyIgogICAgQWRkLVR5cGUg
echo LUFzc2VtYmx5TmFtZSBTeXN0ZW0uV2luZG93cy5Gb3JtcwogICAgW1N5c3RlbS5XaW5kb3dzLkZv
echo cm1zLk1lc3NhZ2VCb3hdOjpTaG93KCJVcGxvYWQgZmFpbGVkOmBuJGVycmBuYG5Mb2c6ICRsb2dG
echo aWxlIiwgIlNJRVJBIFBERiIsICJPSyIsICJFcnJvciIpIHwgT3V0LU51bGwKICAgIGV4aXQgMQp9
echo CgpMb2cgIj09PSBEb25lID09PSIKZXhpdCAwCg==
) > "%B64%"
certutil -f -decode "%B64%" "%PS1PATH%" >nul 2>&1
del /q "%B64%" >nul 2>&1

:: Write open-pdf.bat wrapper
>"%BATPATH%" (
echo @echo off
echo powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%%~dp0handler.ps1" "%%~1"
)

:: Write icon from embedded base64
set "B64I=%TEMP%\siera_i.b64"
(
echo AAABAAMAEBAAAAAAIADYAwAANgAAACAgAAAAACAAIgsAAA4EAAAwMAAAAAAgAMIUAAAwDwAAiVBO
echo Rw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAADn0lEQVR4nG1TXUxTZxh+v6/npz30n4IU
echo kCJWt8F0AyZjQETmXLwgUbZ02dyF++HHBJe4JeoydYdmyaZuCdnNJglu0VRjmghZxJjJhXQJM2NF
echo 0W31t9bSAuUALa0tpe0551sOZheGPRfvzfs+70/e50GwGgh4HsHQjMq2qaYfYeQAQBTJJEfEsO+j
echo KU9/GIDHAE5ZKcbPUAlBtX19FDidsu3FzT8gIE0klwkAAlpltO6grBsv2u07WYe7CjncbtXTaf+D
echo sve/rQQZLoOKETBneEF6IuwHzHSz5uK63GPv28FLJwf+q6WUUMnzjA9ArDFwjayFLXrkWg5qSk0G
echo mcBPuYVAx9RF523aZK0vaP74FUZXYXn13IkN4iK9fbz7s1MrJ/iczqyyNq3nGtiiUreliXtezkoE
echo kpMuhQwIAaJYPcUZMUjROM0V/kLr87qVkylrZydnq6tqE1nam12IebHAJrQVmE3cw0GVvnzAtre3
echo JTjIY+PLra9jRp9SmwIRaSnfJCXTFwAhQjGZjAwM+73GaDBmCWpfCgs7YM2D+5iq30dxhmoSi7WX
echo tx6xYWOpVU4tPkneevhQU6Z7CwDRr53vr8bBM2eWpXj8g6wwPwEEN976/OhYdKT+AFtQWhOfnxr2
echo uw599/j84U/SC5Fexlyso4q2nL356RfX1WazXZalIlR7/LhBbStoWBKiVPTG0DCRd3WoGN27kbnF
echo 3s431qeaqjc2+qMp05Vx/4TH44uts9v2yMlZoTwyvN/j8RBK0kgMkSWXOl+f1lpb21IhVXXgdEfj
echo kPful81V65xaNQMzACAWr4G9dfbRr1v3bJfe+dAZKGza2ky2/baig9qTX60nDNoc/0sVm59DG/a9
echo tyW1aWvDuchcRCrLY8nuCisEhVmZqPXMkZ+vDgwNjpwtKTHrSrqkC8ob0fihY/4bB44OAujCcjaT
echo R+v1XaNTs5InNA8iQRRFREpLZObE6ISMTVxLoSGvNp1OhT0tTlFpQIDnsSLNfE4S5KXEdCKdsyQz
echo WbxWx6HdZSaIxxZBJADPGTS40qJjRDGbIumEf5WE3YSoACq1XX2/Dh70BsmpsTuZe8EQmZ2JkOnp
echo 6RwRl8npS9dDYHpz7bVr/IqKnzHTPz09BCFf8tEfd45VJ2MLdoueiWYkoCkMJoOOuukXyMDvdw+i
echo 2NXQyLaeFTeuAs8rVgVoO/zjS97b96+EJsNJf2AyO/b3gz/bv3HtUnIOx1MnKoR/AQepmeMyotml
echo AAAAAElFTkSuQmCCiVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAK6UlEQVR4nKVX
echo C3BU1Rn+z7mP3c1m89i8NpsAMQmv8DYQxIEmUB9IpWhxAwwqg6hU0FalFCHUzWJ4FBpQrDLYCira
echo OtmCVqUisYQIgqDhTciTJJBkk81js+/d+zincy5odUZUxjNzd+bu3P983/n/738cBDe77HYMDgcB
echo ACFz/l+ewaL+UcwJOUBVROSIF6L+Q9Guxs3dR98+ATYbB06n+kPboZtExwAOYp7xcEasNf9dLjZx
echo KkIY1IgfEBYAMAaMeaCB3kjU3biis3LHqz9GAv90cIrADpB0+yOm2Iz8/YI5YyrmRJB7286SSKAe
echo 8QIFQkBVIioYzXp9xqhXMu58wqaBMxI/m4DNqbleb83ZrEvOGqf6e7qkztoyJRL4L2dKzgRKkOLv
echo awVKgCgSoaKJ8PHpOyzjZ6aAs4LcyNv4R+PNHnZ6Z7GaOmNJmpCQtkhxN5+ItJ5ZAqaUNJ1l6O8w
echo rzOq0VB3pKdtERCqYl7ERJFUPsGaxKfkLgVAtLDQrnnBVlHBAaXopxFwOAh78uxOgb3yqSMKkRw2
echo RPqv1OhyJu3WJw1+DAt6Xg17XWrAPb+36tXPIt0N2ylRAIs6SjmBopi4mcy2uqiU2CnFzuJiFRCi
echo P0zAzk4NMM6xevrQJ5aMrHUUS4w1UqVcyolUZx21DAFKjfa2VUV72kpCFw7d2rHXcZjZ9VXueL/7
echo wIvgrz+CKQDCot7CuEMpUAdCZJz9ubsKNm3K1HAoIP778AuLAFc7gAgpSQss40YvMGYNmXcGof9Q
echo 2zrEm1KQ5Gn/SulpXdj58daGb4zy8wVwOGQ+fRgooQEINh0H45AJLDsQ5OVhQEiZuGNrucGS+qyv
echo rnE6ALTbnBX4ez1QdBiuiwZlC/GmWGPuLfumvrMxm0i600BVoCpRo94BV6G9is9/fKegaaSmhtkA
echo lRQd4jgwDBpLOb0JqBL2QG2tNGnHthLTsJxnMc9TDtAo9q075SL6hgCLT2GVnc/fuVNwlJayGHG8
echo Xp8T7etXeaNBp9LEdV2Vh07L/h4qmq2TY7JGOasd05Wa+k7mafY9ExaSw55sMTET4sfOUhEQIOHQ
echo 4Xz7vTFCQnyJNOCVKaXAmeNyGWagwfp/Aiw+1dMdSs3SpTITSaHdDpQQrATCTVJvfxcWdbdB6JNu
echo qihnqRyl2GCanvarFaOh2qHk2ewi5NmYmymAercxp4AVJUyjAZDdfR+Kw6YMFhLjDbJn4JgSDCIq
echo k+jXmcCznxEPPZRkzB/9ts6a6lF8gVP+llZntcPRlv/Klt0c6GYDh64qYYmJiQCiZwGh8ZgTedGc
echo 5UybvWJWrdPRcv0cefGj754dM2gcoVJEpBF/ONDRc5H0WDhFF6BElmtlf2BCpKPrH4xsjd2uagSU
echo np4Ab4op0CcnmSEleYFoTlgzvnz9kzXLV5aOL7O3I6MuDYuGqxqEIjNts2KjCMaEEVRK2Tdo3qY9
echo gIVeJdi3xWAdqSNyWEWYB0KImjo6AZ94emN3/l+3lCsDvjYK8OCFg1WXxq5bNeHc847TPIt79XRH
echo NH5W0X4lFFoQanfVx+ZkjYrNGvTG+HVrvzyz1vF3pgcAYPUcASfeRlVFS2GqypRGg2tAiEnnDIaF
echo oph5UAn77sGC3kwoVThDXGxU0U0FgH01T658TvMgAC14/eUXOJOJheA0rn61VhNQuKt3KwmFed5k
echo DHsvNmzUpSQL+oz0+1luZ5ZXiAwxc96mtZwxYTiVwxGtAEWD/oi742i7c/WutjeW3d325rKHqBQ5
echo yBniECJEpoJREZKHrDeNmJQECKmFVVUc248z6JdwelHLGsyaRaHdztVuLD/jq2+ZL+j0w3mDmDpw
echo 7uJLgMEEpaW0fUVxOHP+nx8REtLXAaWA9SY9S0dBCa0cOL7Lj1nCslMggDhdaJXi627kDCYDcDyP
echo zUNGJA6/Y785MSeuuqhIzbdaOTUSaQi1Xq1kBL6vQaCJWzc86KutPUrCtK/pnXd81rkvLDJYh7+h
echo hnygSqF6DsiRXlfL1sCnL10CABMMXjgIEoxmCAwMwOUKVpyk3AfLF0tYWIR43UQx1myU2i9Utu1z
echo 3Jtns0OH+3CMt7k5Cu3tYY34aPvqMaah2fMAaAZw+NLxBY++BAARxsY6Z814nWX4aRINfBAZ6Fg/
echo IVJx9sCBpujY+esmLLb98tmczOSiBIMug3I8+uTSFep2+9sv1nV8dHz7y2UApzut9z03jItNnyuI
echo +g2yu+lvVz/a8vi1GkdZKQbNA2PWO6YlTxzzmaoogDAC2ePz9l9oHlm3YYNr0MJtnyNeVK68ubyQ
echo fcxstuypfPnXM25dPsxq/rbnyI66DnyuPwRDVAKNNU3Krv0nVsKnL7yoHaR442ydIH4Qdl0Y1XVo
echo N/Mc245g1h7Pl9iP+BuatnM8D6G2jo8pVS/E56YXQ55NxBx3u+x1l1BKGWfxD7sP/vOe39zBwJmI
echo WDowEVOVELw4xwJqKEgTREnZ+fg0btOy+7bFziotYUidFas/VFWpQYxJsTGLMfYSlh3A2iOx2+34
echo q6f++EywubVEiIlJ9p6rfy/k7t1ryc3NpYD8lozkywghurTsrQ2Dp9w6z+PzSGUnG/G/mly8OxRF
echo YUVFGGHQCxwMizOgKclxfDgUgUeKspS5M6eU4YKn7mLqp4rSgkVjCgNWfaHOG4kQ0lasMHaXlwdT
echo 56waozelf5GZnmVpqHzf8vyWp+vOGvR0jiUOH+n2osaBEBgFDrLjDOAoGAoIIWjv6QNBlVmnhbKa
echo ZiU9Jo7b9+6RL0+9tmzy4Accn2CKmlr3Pr/8ayz8bfVr0wpC0F2+Naj1/4g2bUrHttwXnTazcH5M
echo phV7A2FacdmNesMyxOsEiKgEpqUnauCSLIOOKGDgOfh3ixsa+gN8vxKGnFsskwDGJWBEg0SJyFr3
echo 1roofIcA1aYVqoUUsVot9XZ6MBAPwJCY5OT4SX5KNJfxGIEKFEKyCrbsNLhzcAoQCuD3+bSN+iIy
echo fO7yQIJOAL8skyRLMoLRk0cSWYoCUTTXX+uicMORjOUI8tQ4fZQozaAfbgpLsjmiqF8nkMYzTuRg
echo VlaqZuDzekGWJM0TOg5DjMDBgKSASigY9SKFBLMRydEAlZQ6zSBVq8CAf3AKZjhy5CgkiigYUXsR
echo YdUOaX2UuT6kUOgPRyHo80I4HGId+BqgwMHDw60wOTUefj92CIqjKoIWVwCD3Clz6Ky2v9OplWL+
echo hgTyLmoMo57OAyD1e+pbus7fHlHmUA5DVCUwKdkE9w9KhHg5DEFFAe76cMXKMSM3MjEWRiUaqcGg
echo Q+ebO/zQUd8Qyc5O6wrFaiG4nr5wYw9cu35Bd2XPV7jvmL/2i7N7e+pb4c5UI+rq6YVUEmXTDpzv
echo 9V5vk99SMwCEWbg4rJzvjqKTF1sPAHzRn2iRP4aa1zQR3sTFxKnOrajgUOObZ96rPLlrSlw8t2Zi
echo llR1tQe2nbsCFc3dUOcJgshhYOMWW0yQHFBVp9cLr3xwMnTlsy//xApZbUXFd8BvZiFKKQZIM96x
echo 6vXP3Z4QDQz00faOTsXd5SKdnS7a5XJRl8tFXJ2dan+PW1GlCN3sPCZzv1g1Wzulndn/vIUw67sA
echo hnvXvrX9UE2dFAwEqN/rpQN9vbS/t4d6Pf2U/Xe5vZuW7fn0FBT8dhqzsNkqbng3vMnbsUaCEkIh
echo bsYzBY7HZi4en5NeGCPyORiDIClqf3tf6OTblaf2frj5iT0IQHrAVsE5ncU3vKL/D69nXg9E8Uk0
echo AAAAAElFTkSuQmCCiVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAUiUlEQVR4nL1a
echo CXhU1dn+zrnLbMlkMpNMNkISkhAIS8QIymJDFARls9qJFZW6oFQsUNxa7S/JaGvVtvZHWy2ofR6o
echo +JektBWxiqAYrMgSEKEZCAkkIXsmmcnsc7dz/ufcSRCRLjylPTyTuXM595z3297zfd8Mgss9XC4O
echo 6uo0dpm16AdLeIv9QeAN13C8YGX3qBwDKkVaaTz8XrSvZdNgw58OASAAWIcB3ORSt0OXF3wtB3VV
echo WtrVtxebiqa9yJusCxEvANVUoJQCsBdCgDAHiGqgBfskNdD3Wtf7ux4B8MgA1ZcsBLrcmk+rXPkN
echo 06iS7aLVmaLFwoQipCFKBKJKFIsmBETHRwFjAoA4jmog9zfvGzi62xXrONp9qZbAlwV8dTVm4DPm
echo rp5oGT3xXcGcmqJGgxJwmPKCQZB9Zz+mmupDmB8Bz6zBASWgIk4WnUUzHJNn1wFQAVwT0KUo9nII
echo oG+WkldmE9Pzt3Gm5CRNkRTOlGzAlHDxtkO/BkIOCslpdqrKBBBCVImfA4goEZkQxvTCGTnzvlfN
echo XBBctfi/JwDbzO0m5kk3/o9gyxxLVJlgjATN3/mHwPH3KxUNHRfTCx4mqkwBc0AUSZG8bTsQ5mgi
echo MJgQVFCxqAlJaT+wT7ujFOqqiG7V/4IAiGkspWyJjU/NuguIBhAZDMab9s4LHftgnWnMjO8mFV71
echo G4QxT4mqcsZkTJXYVnmw88eAMGLQR9ahCFPOms6bbCmP627m0V3pMguQ0MqXC1dUc+zNlFU4V7DY
echo nSTYK4f+9sF3cG7ZOOu0bzWKqZm3aXJcoZqmcCarqAR72+PdrY/5Dvz+gOTrOMSZrSwYNBYLCChH
echo EA+cIWlRyuhJqborXRgLF7HKpQngdjMfpiMLVcxO3OaSHVM5jqPKYPvHxnGVS42O3PXAiSqRYoQz
echo mARssAiKv/dIrP3kHG/9K71AKQodf++uSGuDjHgDxoKJ6rEBiHImq92YN6V4GHBCALYfpUjf/98Q
echo AOffeWeZzuVuN3G5XJxzwgTdBbBgyiKqjLB99BTRln0bVSTAvCAQNa7K/u790Y7GhzreWjvdW/9K
echo iw4GIRpq2tcy8Omb7d49G1G45TPKzgrAnIZEE8W8UKTv+DFgts+I4opW3FN6oVV0Xvung23qdpO0
echo a8peT59VHuz78KPldXV1rRUra/Xn1YhvrJCSAZzFkc7cQQl69xE5slnubPrQu//NlgvXSXxAGhaN
echo EcnbCkqgV8dlKZ4OLDY4s10HWTTZztW9XCfl3LKgOHve3I2IEKbwimpKsRsh8q8KwEzHNC0gjM3J
echo JYVXcUmW/Snjxt5UX4kO64uYrGcA6DTE8VTub9vU9afqe849zUxfVYd1ZvmKC1AATeOwaAZsMAOR
echo wiPzQYsH9cuWl9dI4x5dMz21rHSHKSfLHjrRdBIARDcgZdgS9J+7UMIPaf6992YjjiuSfH7N4Eh1
echo Jo0r2VnygzX5CSpX+nVJEUKaGlPZdWl1rTjiLsMBOcI45w9KiQYIYRCdYwCIxlFVYiu2s+VKV64s
echo spVNeE9Ms9slv19DHF+Uf+/SLBbxI/HxTwVwTUjQmSXTOlmwJosIc0iNxVVjhtORXJD/cgKEfJi5
echo DlFkxZg5dnm269nfeD7+NQF3zcVA6+uljilPoZTkcAYz2MpvRgbHaABNQSQeicUinR1sXcsVJb8w
echo ZTlT1GhcZfsK1iQ+KSNzrI7L47mIAExjF1Blf2Ojfi3Y7KnYIFBghB4MUjUaI4I1+aaytStywh1t
echo e7VYkAICnoljSM1ekcaPnwTVNUjPkS4igKLFs6kqW42ZJdSUVYKIpmgIISBK9OjQZ39pZwHLJyct
echo ZPto4RAFQjRsMFAxJytVx1VaehEBmI8m/JRSSlFFdTUf7unRJ2qBUAwYzxESlgeHPkAIMG8xY25M
echo 8cTAgU1tRI42Yt6AKNEUxAnEYM9dnlir9AIBKvQ9lWi0EotGwZx/pUaUOMvrKNJkIETdxf7fnJ8/
echo XrCY2Vws+4PvE0KibH91KBg7f7VzQVy0apVB7esbx1uFwUBAHkIIsajS/dlVW8sd3LLlkLkgV+ZT
echo rKISCO7RJOVGLPBIC4USboJhJ2BuIqMRqsSBtzqXZ1Qu39ZX5/4IHtggwMYV+lpQweiRIiUp9V7b
echo pPkgpuUhKkcBIQ6TeAjU8OBBXWFRSWa2IpKsxvu9nxqznXMl3xCJnTp5hHlJPcAwC41QW2dnuuMb
echo 0w4aspxKOqGhghtnn6SaWnvqV7/9v7qqqiEAaEudWf6sKTuzhreYG6ii9KiynDlw6JhH31CKnRHY
echo iYqYlVSEeYNgyJn4dlrlAwsGNq7YO+yjGOrdKnDcPdYrFpRbJ92gUSXOsUBHQDGRYyGCZZ3Zgs1n
echo DtsmjVU0SfZijI+LScnGUNPpnzZvruu60B91lmE6nPrqL1tMOZkFDAUWBf2u5PO3Dh09/tCJF9a/
echo xx6Y8stn/yj1eHcmFeVfTyiYGlasWcTWyF781Apj9thXiRJnmuaBEop4A9KiQ6DGQ8/LoY71Azs3
echo 9qVMml8pOvP/kFQ43Uo1helYz4n0P0NdQ2pXR2Hngd/6GJ1O/c0vdyGe6w+favnMlJl5/eGHn7wV
echo AMjoBQvGnH333VaGG424SF1VFbni+affto4rWqDJskYpFThBoFgUkBKOkvDJMzOO1TxzgAk1+o47
echo sqyjs9KVqBJsstnOMgvm3PrMzw0ZhY9o8YiKWDAD1bBgwtGuE69zJouIDck3I0o1zmyzY9EIWjQw
echo HM7n+IKgUB8Kdxyf5b1h3H52Y7y/t5BoNCU25O06u+VPPUyxk59fN9/ocDx48L7VS9gpzZ/HNFSN
echo SVupLC/CgqAFGpsOWfJziwWetwkpyWAclf4roDB1+BTsAQD2Aqit5QBKRWyy3ko1hcE5jxgowoLh
echo na7aH72TcdMjVwu27EWcptJI06ctgrPgSSHJUUwUibEXpggRzmzjxeT0peB27yt1VYueug3N5wgy
echo sS81OTNeFu2prSNMpAtQ73Zr7MTsmTlzu8GW3JZcUpifNCbPOXjwyEOOaVe+KDpSM3izZXLRI6tK
echo 3Qh5dGosLaVFPrvQUlUlZd287jkhOS2fyBF2KnF6no95pEYDcrz79BFWK/fVVR0AAPbSR/atz8xg
echo 9QOV4ypCCCNKOQ2LREh23p9x7bLNnjr3QV2IUp1IGHh1zN13TzI4UosoIcdH1hnRFq2uqUGD+/aF
echo ol29y2KdPTFTpjPPduXEu5p//spMJRA6Ysx0iilFBToHu1wugJ5sjh31o1zP3G5ML3iUKDGNFYvs
echo HACEWEWG1dBgrW//5kTQVVfj8gc2CEXz1xuguppXIv0vqOFBmWWrlFJFFxphwClO0eDI3W6beN1k
echo T51bBo8HuYaTxtSpk9JEux20uBS6UABwswyz1sWd+Nn/fuL/wrMweKLpmNmZMb/w+/c/3/Pu+9+O
echo tJ5t5A2Cmc39/JMeHjauULJvqbmNT8naQoEyAmcVF8KiCWODWZQH2vdGvKdWM9APzBmDaU0NfP76
echo g8qZD9ZKpTABe9+3t8o9p5ZqsZCfNyYLWDCy2gBpiJP51FEZyfnlu5InVZawWruxsVE/S0SjaAmd
echo PNXo/fiQe4RKz0UQA1/qqqVPY0yGKz1h4pOPLhTttkXxAd+fPc+9uLv00ZVWjyW9nwVt9sIf3iZm
echo FG5BnMAhFkqUghoLqlSVj9Bo6LVC3xtv/rW+Pa43iP7BSLlqwRhLwYzlnMFyCyeaS7AxCaiqAFJj
echo oPk6jvl7eyuDn73uB1SDClZ3pg/t2BO3TChP79xeezpBv18fBntRkcHX0pJICS8yMq57sNKYd8VO
echo 3mwV1NBglMjx95Rg30dyuHePf+/vTnyZAOXnZXxz2XXj83OmmI1CiaKSjGgkSsIR5VRTt/+LeFvP
echo h9D8hn5wMQWnzVk13WjPXowNliXYZC3kqQpSl+dgR+PhCrh7tnyxgiaRq9TVkUk/enx5UmnRt4hG
echo WDFhwAi3xXp697Rvffvn/oaGIFRVYRa4WTt2GLmxt3sM6fl58d7mXTTQu6p75/qmEX/Udxi9ZMby
echo VXeuriwvWTCldExSntMCJkb0ANAcVGFXSy9I/ig0HDkFn3xx5kBHZ+cvcP3P6s5DZx51y9M34+T0
echo 5wwCnxtpa3ipe/eGNRUV1Xx9vVvTM9FhYfjy1FR8GEATbEk2k9N5gxpneQkAb7HkmEfnzOTM5hl9
echo ubkLC+/7nVLvrtTQkh+tNDrH5MV6mnZ11T6xGADi4KoW96ysIZWVCC94/NUff69qztr55UUjacpI
echo Kq0fmjE5Ajv7vCQv1QLl15dw104tuHr7J6dr91iStjv79n337JEPemAdiXe60Vtpc1YfQjljD4j2
echo 3BXp17herq93Jyq68yyBD2/cyPp+6MiGzS+FT59pAoSIEgpLgWONR2J9/QHHtCnXpa9d+e16d6UK
echo 5SBwppT71eiQHO05et8IeG7bM3JlJRIe+9U777z5zHcfm19exIJOVTWNEko5SoGnAByhFE92WPHK
echo 8Tl8fyDG727tQx1KmGxaOUN9+M75iwMFN3yYO/uuQnAjMsr1C9PA7pea5WD/84ItyyBYnbcl2AZg
echo 9De/mTVSl7M/VHePlhYp5h98QO4fwIbUVIOQ5pAH9n52d7SrZ7NgTVquBxy/JIczpxSr4cED/k+2
echo dkBFNV9bW6NphJh/+MqO7eULr73h1NCQMtw+5HmO02OMsn/saEAIKEIwL98JV2emgEPk4a7ibMwT
echo ytcsLlaeuLNyfNhR9peiWa70TsiVGUgtGKxT41HCGyx6C2GUy2Owz7zyDqjRaw2UoFHWTa6uxsef
echo +MneyOmOuZEz7SfFJMs1qVMmb/Z+uHdH5HTHT6tpNRYMjlRssCDMiQcZ5bkecuEqhLR5K198rXLx
echo 7Dl72jqVHJNBeO5IK/ppQwsMxmQd9MhLF4YyYQAkRYVsAwd5VhPEVA18IVl4bE6BcsdN14ztSirZ
echo RIdL0P6m/T2aFJawaEphzxtFUYh29DXqld5XamLmV0wIt3s3AEwuXnHfFM6YNM6Qbj97rPq5A43P
echo AaTPXaM/RDWVtZnpttuQLE5ZtnjZ0kVL6/v7FYfACTnJJmiPxKE7IkFnpBkmOZKBQwimpCXDVRk2
echo PRSYLONTTGAwUpAIBQ4jPUCe3t8izJqcqn7eVHYjH12zCPau3w6dzfxw2akzcsuWN0MASE8sv14T
echo u92kOuFbSvOGNw6eXL9+MwNfWu0S9dlBr96QHRmEUuPc66/9cVZhJj3ZN4S7ojLs7/bBaIsBTDwH
echo QUWFj7p88OfWfvh9c08ikoeJe362DaY5rRBTCSQLHLx/dgDquwbhi0AYzZ9aQI3Jjif0qVmiluCA
echo YcpnVd55Da6vdSXYiTxMr7iitBSx084zXNhIUiDItE8RTTznvHnKrKkTJjUPDVFKKMceXP+3s2Dg
echo MAgY6QFm4TGwSLi9mNXiCSiqpoE/FNbdySxw0DgYgR1t/ZBpNkCLL4KvS7fDqIy0aU3Tl+bBZ2+d
echo ZbGqybEvlX0eC/29tgplcVH/5UfEwt8oh3uIEmdK1C0iTp5QObZoND0Ujmkih3kGUMQYNOZg+imD
echo IKyosHx8DpRn2JjF9FgIh0LALMlhDCqhsO1ML8iEQhKPIaqoKMpRLX9UFtfUlFIOAO1AiIAxf5ot
echo 6fJMQHWX3plLWM/rqWftwgjidKyQmmyaKBgEFJIUxPxcN/TwbAY0omgwP9cB8/KcoA2Dj0ZjIMXj
echo gDAGHiMYjCvQFYnrVkuYHiBOCc1Is7KGk96BAKJiVYr42WV/f6LJcIkC6DzI5sYpkBNAiJHdFICk
echo xzUCMmHN2a8OBphpdHFBhs46TMC4JEMoGGT9owQuSsHIM3fD+jWbo1AKIYWAUeQBC5bhxWSiqape
echo an7pFZcmAFTU1OhzqRRrAEr07DCuqKqsasBj/JWulW4BQDogBozhjcXjEBjyj7CfPkclFGwiD9fl
echo OHRrDUkKpBsNMGeUHSRVAxILJeKGaAEERBcAZieylUvrjTLJPR59ZyLHdlIMN7HrsMY1+4ei8yxJ
echo PPVTCXi9ZZbIh+KqpluhNyqDHRMYGgroPn9+bxYzq2gEFuSnQZLI6640d5QDRltN6PmBAABVPPeX
echo lwvvqsqJ7i6v3jy4MKH717vTw1+dSiFvgxb26wEV7+/+4lRrH8owCkgd9nG9IYAQLMxLg6euyIVM
echo kGDwHPiLD4VQuH5UKiwryYZMi0hPDUS4to5eFWKDDX9OKbZLocHD4KnTT+Z/+xsaX32gJ9zu2aF/
echo 6Dq1+8DRJqnYZMQqBaoRArG4BNNtBvhOgQ3GGwBYa0rkuYs2Rs8fzIUCkgKiwJEjHWHa3e/9HH3+
echo ++5YKK7GfK0b9EluN1yGr5jqtMiJnY2szkW9e9qPNp/d1tXqR4+OS9NQKAjhgB96fENwrNsH+/uD
echo 8NfuIfDGFBBxwr3+3sCslYExsH7Itv1nUKS//VU2P3RTmT9y4tPG4Wn/1hcc5w8EpY0sq0FyZ9u6
echo X//xE7XQZEQ108bQMocVDnmD8MT+ZnjhSCu8dKwdftJwWhdC+AdCKBqFtCRBffv4AF+/r+Fo6YE3
echo tgynziPMfNHxLwfxBYPqC7s8HKqrO+1JsT/48NaC1zYtv1p9pCyP+3wgjAYlBRxGARxGEUJyAjz5
echo O+hVjUCqWVCbBhT+ha2f+kJtTbd7EJLPZcv/0cFcialo1upn1/52L42EAjTu9yr+vj4SHOinQ95+
echo yt69fX20r7f3K6+enh7a3dWtSUGf3NLtoxU/3DIIk++Zlei2fa2r/Z8XAq5Zu+yBl971nfUGaTQU
echo oP19vVp3d7fW1dVNerp7dMDsvbu7m/T19qqBQa+mxCK0/m8ddObqDYcg/YYyPPKbi//2cI0IAVeN
echo mbXq5U2/23looK3bS8OhMA0HAzTo99GAb1B/j4SCdCgQooc8bfSp13e0pC148vt6GpVY6JLAX/Zf
echo q+A/VGkJX786/+bH77xldnnJ7FF2yxVGgcsVBB7iMYlEZLXZ0+nbt/Xj4zua31r3EQAMYZZOkKcu
echo +Sc3/w/yQ05rwUlRmAAAAABJRU5ErkJggg==
) > "%B64I%"
certutil -f -decode "%B64I%" "%ICOPATH%" >nul 2>&1
del /q "%B64I%" >nul 2>&1

:: Backup current PDF handler
set "CUR="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /ve 2^>nul ^| find "REG_SZ"') do set "CUR=%%b"
if defined CUR (if not "%CUR%"=="%PROGID%" (reg add "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" /d "%CUR%" /f >nul 2>&1))

:: Register ProgId
reg add "HKLM\SOFTWARE\Classes\%PROGID%" /ve /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%" /v "FriendlyTypeName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%\DefaultIcon" /ve /d "%ICOPATH%,0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%\shell\open\command" /ve /d "\"%BATPATH%\" \"%%1\"" /f >nul 2>&1

:: Register in Applications (for Open with menu)
reg add "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat" /v "FriendlyAppName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat\DefaultIcon" /ve /d "%ICOPATH%,0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat\shell\open\command" /ve /d "\"%BATPATH%\" \"%%1\"" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat\SupportedTypes" /v ".pdf" /d "" /f >nul 2>&1

:: .pdf association
reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PROGID%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1
ftype %PROGID%="%BATPATH%" "%%1" >nul 2>&1
assoc .pdf=%PROGID% >nul 2>&1

:: Capabilities
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities" /v "ApplicationName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities" /v "ApplicationDescription" /d "SIERA PDF" /f >nul 2>&1
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities" /v "ApplicationIcon" /d "%ICOPATH%,0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities\FileAssociations" /v ".pdf" /d "%PROGID%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "SieraPDF" /d "SOFTWARE\SieraPDF\Capabilities" /f >nul 2>&1

:: Clear user choice so Windows re-evaluates
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1

:: Instant icon refresh (no Explorer restart - just notify shell)
rundll32.exe shell32.dll,SHChangeNotify 0x08000000,0,0,0 >nul 2>&1
ie4uinit.exe -show >nul 2>&1

:: Create uninstaller
>"%INSTDIR%\Uninstall.bat" (
echo @echo off
echo net session ^>nul 2^>^&1
echo if %%errorlevel%% neq 0 ^(powershell -NoProfile -Command "Start-Process '%%~f0' -Verb RunAs" ^& exit /b^)
echo echo Uninstalling SIERA PDF...
echo set "PREV="
echo for /f "tokens=2*" %%%%a in ^('reg query "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" 2^^^>nul ^^^| find "REG_SZ"'^) do set "PREV=%%%%b"
echo if defined PREV ^(reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%%PREV%%" /f ^>nul 2^>^&1 ^& reg delete "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" /f ^>nul 2^>^&1^) else ^(reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "" /f ^>nul 2^>^&1^)
echo reg delete "HKLM\SOFTWARE\Classes\SieraPDF.PDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "SieraPDF.PDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\SieraPDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "SieraPDF" /f ^>nul 2^>^&1
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f ^>nul 2^>^&1
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "SieraPDF.PDF" /f ^>nul 2^>^&1
echo ftype SieraPDF.PDF= ^>nul 2^>^&1
echo rmdir /s /q "%%ProgramFiles%%\SieraPDF" 2^>nul
echo rundll32.exe shell32.dll,SHChangeNotify 0x08000000,0,0,0 ^>nul 2^>^&1
echo ie4uinit.exe -show ^>nul 2^>^&1
echo echo SIERA PDF has been uninstalled.
echo pause
)

echo   Done.
echo.
echo   SIERA PDF is installed. Right-click any PDF ^> Open with ^> SIERA PDF.
echo   If the icon doesn't update immediately, log out and back in.
echo.
echo   Uninstall: %INSTDIR%\Uninstall.bat
echo.
timeout /t 3 >nul
exit /b 0
