@echo off
setlocal

:: ============================================================================
::  SIERA PDF - One-Click Installer
::  Registers as PDF handler. Uploads to MinIO, opens in ShareSuite.
:: ============================================================================

cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"

title SIERA PDF - Installer
echo.
echo   +==========================================================+
echo   ^|  SIERA PDF - Installer                                   ^|
echo   +==========================================================+
echo.

set "INSTDIR=%ProgramFiles%\SieraPDF"
set "PROGID=SieraPDF.PDF"
set "APPNAME=SIERA PDF"
set "BATPATH=%INSTDIR%\open-pdf.bat"
set "ICOPATH=%INSTDIR%\app.ico"
set "PS1PATH=%INSTDIR%\handler.ps1"

echo   [1/6] Creating install directory...
if not exist "%INSTDIR%" mkdir "%INSTDIR%"
if not exist "%INSTDIR%" (echo         ERROR: Cannot create %INSTDIR% & goto :done)
echo         OK: %INSTDIR%

echo   [2/6] Writing handler script...
set "B64=%TEMP%\siera_handler.b64"
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
echo CgpMb2cgIj09PSBEb25lID09PSIKZXhpdCAwCg==) > "%B64%"
certutil -decode "%B64%" "%PS1PATH%" >nul 2>&1
del /q "%B64%" >nul 2>&1
if not exist "%PS1PATH%" (echo         ERROR: Failed to create handler & goto :done)
echo         OK: handler.ps1

>"%BATPATH%" (
echo @echo off
echo powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%%~dp0handler.ps1" "%%~1"
)
echo         OK: open-pdf.bat

echo   [3/6] Writing icon...
set "B64I=%TEMP%\siera_icon.b64"
(
echo AAABAAMAEBAAAAAAIADIAwAANgAAACAgAAAAACAA3woAAP4DAAAwMAAAAAAgADEUAADdDgAAiVBO
echo Rw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAADj0lEQVR4nG2TfUxbVRjG33Puvb3tLS0f
echo a8fHKGxssDGzlshEsWzqHCObCQ6dRrOYMTVDsv2BH0Xn1EI249REjG4kIJKlTjSrLCzyBwsuZhIn
echo GYM1g2xslXVCeym91AJt2aW39x5TErQaf8nJycl53+d9knMegP9it+PEln+wvWb9q529RbWtXcXP
echo vr8t+S4ZlHwobWtjhuvqpPyXO2ppRD4lRIlTKYYsFJ0V2TnvrtHu4wMrNf8rkCCvvjWdiUh9QDGi
echo QrGbiSR20DrDO0x4evCWo8EKAAokQSds2ZsAej5P02t1UDxxIe5XGdXZCqW6DEr8xD3H4f5U8+5a
echo wwOPmw9BKeVq32+lQ9OuykYu2tyU5GB7y8liOT/7RtQfqw8NQqO0MFHO95wMAoBaW1jOZ1n2Cquf
echo ST+GWdaJ7wYKBmw2z7KDh79qKUYGI41c7mk5MxZSZ6E8kJUAa9zggOfOVdO99VtWba1JV+H0LqIh
echo JcpizE9HvCFrt8NCQkERY4KrVVruhmgusMV9wlPchshpRCmLjFq3Z6Mu8JKp5u33uJzNoEizhC1h
echo Tkm8UC1aHvyA0qW4CKGqMHJ7W+NT/PdEjFVca3x36M4JTbl6dW7lfFDoud155Iyn6/wLYsjvooym
echo IzOvuHPWvXV0hCwuPSpN+s7GvGMdaGvn6YeYVH1+7I9bvwZH1xRhrPo4dB9a3txdFCnZtMZ6jZ9H
echo 3/14dcwvabVZJHiQXZo7wJUxUVyQ94gSue+hGSBVFEMdp0xr91IjpHTi0oUd/T+dOmwtNH2iYTAY
echo wgro9Qyo7/kaG76+eWCjgXsaCjPHMVL9QJbmbcuvUPbZh9soRSfc+S3+5P49Zn7LE2Xn+T8F2ZKR
echo QnbmpIHXO4kGfCL15dkrL8ZC/oxVFWxvTCJrh2xHf6ETAlffODaAEQb1rqYKlZ6rvR4MKXxgjuw0
echo GWn10iK4hYV4fyCsrM9L2zc4+Xv3eIN9EgASC5b/9mN2Oy0rMpKE2ethUeIicRnMBj2ysDJ4ZwQw
echo cCxU5WaAgWNIhOdHCCGo9FAb87fA5ebmuNMJWBr5YlgMLPRtohHOic3LY54pJU6IvC5VAzuyjdg3
echo E3WGR7+9/bzTiYfb/8nDCogQgnNzX9e0nfv54pXxu+TmhIcIPh+ZmuLJR2cuOhIDEzXJGfp3mAhB
echo CCd0gOm7NPRaXqa2UpSJNOQO9tTt2/5NwjpCyy1kpecvVkmetNl4/I4AAAAASUVORK5CYIKJUE5H
echo DQoaCgAAAA1JSERSAAAAIAAAACAIBgAAAHN6evQAAAqmSURBVHicrVcJcFRVFr3vvf9/9+8lnZCk
echo CVlIQNYEFCWJgEvHBcsRS0ewg1MoCIzAoBgBR0Sxmh63EZgBQRApCCqjQloZxGEMKEqQYTFsCQbI
echo AllJZ6M73Z3e/vLe1O8gNYyOhqp5Ve/Xr7/cc9+9591zH4LrGfYSAq5CFQDQ4BlrJ/CKNJyoUlgI
echo uStO7153NvaNw4HB6aR9NYmuFzxz6soCYur3JhAyDhMOQFUAy+EwH/WVks66xZVfba4HcGCAvjmB
echo +gTuYBiciGZOW/MIMcbv4EQLr/rdEQo4gjh9HAPAvKAHwdfcynfU207t21DX10jgXwfXDAEbNPWN
echo YcQQ97EGDr6WKgh63gVOj4FRBIokS9GQJMWlpkrx1k9sNhvXp4XBLzvQG52zOQgAMWpI/BMviHrc
echo VbtUCgZepZbU+3jRHEfl6BGmSvt4nShIUiTCLOm5vvi8Qm31NpuD+7VI419wgNkcDk7Lu2XG6nie
echo ypO5tqp3QkS0kMSM7ZxoyVEiPTKj0jM0GlnNEFIJrycy0TFVZ3xSM2C15jB7SQnRbF2XAzYNGACX
echo OZ2KlgKTyg9HTIWwsf9EMXnwi1SRJCXo2S8H3Hc3bis61bTj+W86y4obom21PAVAKtGNGDJkiM6V
echo XcVchYUq2GzcFUd+MrifCTsLg8cwfvPavRGGnaeeeqaUzFhlomIKD1ROkT2NS0FRd9ZvW1AT+8Nu
echo J+AqoaEGqzfaXgfJBXNArxOMXEKCCZzOy7mb103hGS2qqnLdCwCxLfyfEcHXwDscvblShETOaBwn
echo Dkjak7t9fV60NXwR8zzQaPjgxa3z/xwD18gZA3dpi2ZYMGCsNwPm9YCABaeWl3vztr5zvy495VMs
echo CBMs7YnxvYm9Nhv4x5Dbvv2Wm5OaGgsTn5Q8gvFExTyPCdZvbD9Z3qWE/B2cqd+kzOnvvASMaY7i
echo XnBgMOR+HVUlq2XUfaBPTAMWCZ5xMmBYFN+LhVUnABmWMVS7H7tpUwzrSpohdonl2umEst4oYIaZ
echo ACol0mVPBWcw3HLP9nHChW3qd9gkTMGcMA8KClZAQQGFbDsP9hIFnGiokDU2VZ8+SsFymMPB4J68
echo hpL+nJEOlLzdJ3UI38JUzGuOn0BIvoYD2fPnm+JuGjKfJfYL0ID3SPnMhadDSxccNphM7aATTlJF
echo yeHvdfew9+OOUyU6BQtiRlbW1BUNzvmLAEACJwI+LvmphJsfxIjjFYh4AUf8xzlfhKoSKKAoFTQq
echo 9++ubz4OCLGbN6/L1cWbx7Eur3B51971XDBYpSSQES9w1qRERRQhf3vx31SfPIsFu+dBODpajWNb
echo StFaKfOJtZLGHypLMtGbFmY+/raJcdz7kZZzObr4lGd1SZlUlSICKDLwFl3oyN+nd+XesHEr8vub
echo qIp+z40bxPILij/lTaYpvNkIstfXWGc2v40bPyiLMEndr1z2SkowWG8ekvU4NqO/Hnl2yS5vdeOK
echo 5n21izWSIcyN1QiEgHFUjvYwRfocMzTNOPCmuXz8gJNUVYABkpHOCIpKbgEn0NAXlYuCZcdXHC16
echo oVTPWzaaBmVNkXt66hRPtwySvA9cLjXG+nFvOW1i9rADPYHAViLq0xBD93lqK+Oql6wKaBxLL1yZ
echo p4tPLmNURVgQ9UokcKaheO6NP+Yx9WHHGEPqsFOqEpUwItgQaKmVGvfcWn34cEB7f+NKh9Wcnd2u
echo RMK7aFSKmkTD1ND56txjS189gTU2Hl3iKJNa3H/UE+53cmvHfiUc3mMwpaZr4GmTlw0VLIk7Ea8T
echo sWDQg6pQEdNXCO7d0Np0f+48TUPeDZzOJADhOSkhc6SQPvETmw04jXjEbBko+fyf046u43rC/1a6
echo 1D5PA9ewr6nRdzz33AApI9lWV3ZsT9akSWrrgVaD3pBxmhPNaUrIf54n+LuGpvq/SHtfqwYYnQDj
echo J/cHTAicOnMZQq62odNX38l409MKkLsNprgkzl35cWXJn6ZlOxymyNmzxHrb2Elwprb06JYtnquV
echo L/91RzYelD4dieIARZa+Ky+ctdnBGHYiRLNmbtxPdMbBUvelOTnjxYOlRUVR+0sf5T9QMOrFTGvC
echo BFFHrA3dIXToQruvq+nyyR37K9+A/a98Peqx1/v7TSmPGqm0TvA1LK747K3VjDGEEGL5rq1PE47P
echo p8Fwi1LfUIzyXnPkGkYPK5d5DgjHQdTTXfr9Y7N/kzlr/V0YuNKettbMrn8627T69d6uo2sfuvPG
echo BSkJ4tWodcoKvHq6CcyRCOgudcNHX/3wQU3x3JgYDXxind2s+LdYghfSDu8uDuTv2HJIsFhu08oY
echo 9gVAqaoZicuXOY/LjZeWayoSbussYZJivKdlXSJE0QOM0p2dveB4UfH+zXkTb12QnCBq9VybjFLK
echo knkOHkyxsC6vR3369hRlzVN3zxgxc8N2ADtp2rbApSLSHeiJGzPh0Ps3MFlVpM7LO3lZBepuX3jE
echo +eZ57HA48OFnX3CqTZfmGggXVmsbXlZqu4JEx6USBI0aiea9+dmstNyc2T5/t+Q4WoM/rG4l1d1B
echo 5JNVpEUmWc+jO5KMRJEYN3IAkqZMHDM1+aG8aQCxtTaDRTc86om65XMXX9NjFJLrm578V9GLazRs
echo zqm1TYyhQwhtAoBNDgfDzrsQzZrxLnBYUbXqlbXz++UN0TAVOyKcRBnaXd8BO+rc8OTwNLAPSYEb
echo RAzmRANoNXZDRTPhLHo6ZnjKkq8AfYjxCokBUk88NDfkAMc3Tpjz9RVRQhrPeuUYoVjzYc3JYf/w
echo ntAEijKggaikBvLtK7ONqdY0X0+AHpRUrCMYtDkoToR7MxJjuur3ekFPMBxp90GNN0gGxjNIscaN
echo hJQFyRioHxDyajAHHIDtOSWxnedCSL2mH4gJkqaMtl5JxgDN4WhUHjAoZTTV65jc46cih7HKAASC
echo 4JnRAyFBx4PX64VQMAgmgYcqTw/wGEFIUanBYsQwYsBgQuVupkjuGAYAhcJC+osdUZk1JybYjNEz
echo jCqhkETFqEIRQr1SLqkU4gQeMs0i9AQC4OnsBIx7m52hFgOEFAoJep4l6nmtN9JxNNoiEbUp9oHT
echo +ZPWjPvvB+Dq9ZCGu8/wiNH6Nh+EA2HgOYxAYUAIAaueh0vtHRD1dcdqIUYAUZXChP4WMHIERlvN
echo ZOs3Fyk0d3Tx/U0V57lLHVess770hEy7NF1sbrHizmN15Wcrfc1uOUHgcac/yCZbRVicIQIEfIAw
echo Ai0yP/6kzbxkMzUKelrZ5KmFui8vIE46oInO/+qM0c89vPoSIWCMQcGiD3Yun33nI5+dr5MFhPhk
echo UQCOEHhwYBIIGF1dlkIZJBh46ViLLMxeU7qwo6RoTax7QrHdev0HE/boo0QroQe+OPr83oPnfcvG
echo Z/MjEoxyvMCzdIMOJEqvOAmgUkpNOiKFkUF4b0/59x0l695lWt+Ilvf9+PdzQysWvY3jy7ev+rjM
echo HfZ4mN/dwtrqL9D6mhr1Qk21Wl9Xy7paW1h9k5v9YfXuQ5BsT8FabjQH/i/DXkJiy+g3PW3ppi/X
echo Hzha0XrufC1ramiMzTM/nKNflp2omvm6a6FGbI2UvVXw18d1nY6xq1CNbZFhc5JWLXv45tQ4fQYD
echo UCoaPXUriuwnACCKMQJKaew41xe7/wafECa29FYrAQAAAABJRU5ErkJggolQTkcNChoKAAAADUlI
echo RFIAAAAwAAAAMAgGAAAAVwL5hwAAE/hJREFUeJzFWgl0VNX5/+69b5s1mWxkIQuLBMMmBkWkJeCx
echo oIhgtUNrqdRqBdRiUSxSQYbBBbFVtK22Qf9yuqglY1GptUWrENsqKpFFE7YAIQlZJslkJpOZeeu9
echo /3PfhIBtbUVpe8/JyUzefe/+ft/+fS8A52oFAvjMr8MrL8+YOPf2wvFTvprHANDpbfa+we9fdJ2b
echo B/lrCITmWwAgli544gYsO76GqDkOI3AjyzQFqreJRvKvON7+3N7Xfv5O+iaGABD73xMYAF9wzX2V
echo SnbJ04LinciYBYxS4L/5EQgTEBCAmOgCHO/c3Nm4e2nn/jcS54IEOhfgi76+frrkyXuVSA6XpSU1
echo jLFs6aqGiCAiTBAAowwQY4hgN7Kw0Hv8L3o4Mrthem4SgmvZFyHxCbs9q8VtOTTfKvEHKiRP3jZM
echo BKelJVXB4ZHFVCRCtf5tWFQQMGCACEGABMxMHGdYt3ylXxZ87ucgGKR+//zPj+ELEEhrrrJSxM7c
echo X2FR8TBKkai4FSHe/j4NH1uAXdkVgBAAxozqqSSjlgEIA2GWFKeCgX1Fc8fOufM7oVDI8nNNfiEg
echo Z7uqAgLUBs2y6x9dSHyFv0SWAUTraxUTXcvjsfb9qGTyTwTJ8RVLTRhYdopGpHU9cfluxoKUx6jJ
echo GGAmIooc0aaWcCp8fvur1akBKOy/o4HpQDl5JiqLBCKAHD2+S9z960l9cp6HlEx+dwC8RhS3SFN9
echo B7XIRw8yanUhIgJjjCJgWAdMwZVTkoMc8/ijqqoCn0sLn4mAv6aGAOMRY8D2g0FadMWKIiwqk6To
echo 8bDW2bSyf/Itv5F9uc8AQIalJg3i8MhUT/Zayb4FnW/8JkGT8QADMLHoQMBsQTNTdDEkyF/9hwMZ
echo Q/aZn2EJn2VTaL4d49PgG8akiWTmj1IkUdai/Uf1kkk/lR3ecVRNAJaciFFTNBOxv5qxtltbXwp+
echo DAGGm4PodxljZx71VswolzIKKEYIGzwuEbmCa7O2Npg+gwUwIERDANYXJcCBsiueeELupambenZ/
echo 9FxjMNg3cukTciOAJTCWbzEERkZRpSS7JWqoQC3zKNN7/0jV5MvNW+5+c5B0kEdShpIZQ9pTbQfK
echo HYWjWeYFczBxZfAglVtefqn70KF34lWBgFCLgmbFbbfle88rmTdr2T1PBxGiX0gDXfVvEEflVx7P
echo u3bWMnFi+TcO3P39PbagwCQWwoAFWaCG2mQke1eyY+9ta90VSqXpI4A1a2xzAwDCpYryhqkYEGg9
echo zaB2NoJ83hROTEhJPoETrEXIHPez9dO8hUNfQOFuHETo6TOFeXY+EAikTSV3dAFgZBGPa1TGsLK3
echo xv943USbgIijwCOjqGAzEX2q5fm7t0y5y6/byY3/cDtPgz+9LMsmxp0Zyy7GkwTCKJIrdfQDQmzC
echo xvXTXUOLX8dORyFDSBh9+w0++760z8BZEfCPSdu65HWdTzxuh9Gf1AS3K1MpKni+snqRiJP6EWrq
echo jJkGYIf3hqKvrpsQqq9nEPLTgbrozHWKSAYH4xw6FslDRjJk6QCUttTV1RmjH1qZrRQNeU6QJdlI
echo pQzicOR4C4rPs2UJa9FZEwjn1ts3IcUxCsky3ymY/XFLzskeDbjCf2LrqoMAtA2YBYLiGid6c14r
echo 3dkkDdx+5oFp9ZdWKczUSqSsYvBNvBoAE0aoAUCND/gmV27hLVJ2VqGZSFqAAGOnAwSnewS/tnPt
echo p+PEZ4YtP6shVTt2CJ8ojREiWJYY1fSjVDObsCQx4nR9JS1X8x0kKsDrH+LwFLK8sZem1VeD/44A
echo clmR84DRAkdRBbcHBNTCWOsHDNqfbSAO5cuYEGZp+mGqG61YFhlCaDCU+mv8NjaOMcDYYEmedmKE
echo 2N+Hrf7CasJN1FoX+xgBQ5Rax5Cux7AkDgeCbUkzZv0ZGPPbFSfCnNgaAPRWVcUOVDuQL2whIWSq
echo va3XKbnDsLOs0qSGSggmmKl9UZX1fmgTkASMRBGoqv4NC86xzDBLtc7uA3b+2bkTQjN4mA39gwZs
echo Apc+cv8tQtnQ61LU6sIWq1d7e/9Ut3jxXlgM0PHtkzuK8/PaBLczRzeslxDGX7dSapOtAEOr5+ET
echo IZCokaLElVlVumDjhtrgjHv49Qp/QGqoWWsAQl7BkXFr1kVfY1iQCDV0JgqAMDMPH3z51z32szSj
echo mYvS0vW3JFOZpXV37tt9tPlDLtxaALOyeuNkweueSQGd70Q4W29qffrdlWtetAlQQmTZ45lFec2I
echo EGC344GLt/zfb6MN9csOBx/rzj+/7OvYMjdbqt6kdoQN1hf/Pb9P7+/SBIcPIK1pQvWUJXrzVpTd
echo +GRRsqd1eUMo2AkoCO7hF//cVzkvT8optZieJEAILye4Ddjg+TJV9VW1M/xtiCW6EUPU6oleD6GQ
echo Neb+VcWe8pE/xbI0jzidwBgFUTNAx/iZQQ3ofdHdWriLWm6XxQAELApEycle4BsztmJCIHDZeyuD
echo f52wYtk1SBL1foks2f/91PtcteQbD7uRIAMzDY6G2yThfQCzTMuVVbx92E2bTlp6skDyDrFDL1Xj
echo BDDhLo0YYrwuKjrl5PH9ja/T0SW34mj0eH80NnP/w48dnrghUCiPGL5DzPCOsFIpMPrjFqLAtN4o
echo S3WF9w4SCPcZ+5yJZIeYk5Wf6OreIzodpSaCbCk7a6I1QlsNjP1gH0L1A8I6UrmoWqxDyCALnpiL
echo BAmoaVDeWvGgDtRAybqttzvHXZGDnBnLRVeWi8a7fm4xqBA8WdOYrjKeCgwKTBYdFWNnLir/eHv1
echo oUa01gD4weYznV8oKtwgZnpHUFUDM5k6SXUt4srJHWO1dR7Y6/Qd5UIUqnYEhNoZwVTxow9ulilb
echo JfoychNNLStdJUODAkKFSBSvLb3xxtU3BgJ6kLcAhYWkbvFio+TawHDi8NxM9RRDiHEboohIiBna
echo gdwxeXrDlh9yP1l6Ck3x9Y8uRFisoqCavLukCFmWK0cQ1b51gND8ykXVwvDLa5CdS7j/QF8mEoTZ
echo CGOwNO2QFu7a6BxWer+g6VhLqdU8QFRNBwHXTl9r8UlBpOPoBq25dbfHm1nsKCq8ruvtd6vMRPKE
echo 4FCGSUVZ2cGBiFK3ZImRW+V3k4yiLUSUvUAtygsaHrCwKGNqatUNoZDOtVQV2CHw3oF/NuMnXzMT
echo vWEiO0XGmI4pQ0kQLZZR6B931R331m1abBzb8Od0+A0GKfH6iuSszCwj3r+3bcdfrlSKC292O525
echo qZaTbxiNLb/gmGtnBC0e4lhw7Vp26EfPxo1oz5xU/cE/ej3uK3LGVTyS2FN/laWqB925Pq8di8eM
echo YVAyTXGVTX+FKO5Jlp7SAGOCJQULikcy+jpfgpYPN1cEaqQ5149it4+ZzmpuH8NSBT7UXvlohCa6
echo rrf0ZI/g8EhIEDH3hT7Bq+Hs4gfHz71zYV3dJmNkJCLati2LPj0W2xt7d7e/cNKFv3JLykWJ+kM1
echo kGLX1VVXmxzzwGgjXe+H/H7KyfDvUx64b5aQnzsv1dK2NdIe+UApcJGGtY/18uul33r8ZTGjYB4z
echo NUCCCJaaMIHROqb2P3v8uTufJgixf1U+Fsy5p0TOKv4+ItJcLCkjuQ8xQwV3osM0oi3XNfzhyW1+
echo v5/suWBkVnzn7mRx1SVXOPLzphkn27buCqyvHUy8oRDmZf4naozxy5e79j/6aOLTDi9Z8NiPlZyy
echo 5WYyyg/daZnWi6D17WgJrWoYLLdKvlNx4ewpM4pzMyplh5KX1Cn0RaKpxrbej9uOt7wNdRt32Psq
echo 5ziLR1/2JUFQvsEE6WpZceYoPY1xvbdjyoHtT50KGH+/yPjly5UzMaLKRYsyxInlj7DcrKkIUAYg
echo FLGSqTeN5hPr965a32VHnE2LzGL/hqlybulfqKF1GH3tS1q2/PAV/gButFzi7svvq7pr4eUrplSU
echo zLygvFTIdSPgnq0BwAsNYYhFknCkvgneqju691Bz+yNs+30vnCJdMmtZARScv8LjcCwj4QMf7O9+
echo 51J/Xh4Dv99upioeDpS4i4f+EMviNADg5tzDOjp3nKx96V4h1tysDplYXiX6fOVafwIEhzLUObRo
echo fJyQKeOXf+tyt7tN4z0rcTy5lucbPdY2t7Xm3g9gUbVYvagSFk+axL67Yev6m+ddcvcl5QWDeWkw
echo FALAvmgEwpSyMRPz8ffKXBe8+WH+8687N15ZKRy5Lc//ZCo0H7UDwJ3FC39GcrLLlk40tNmh0GPb
echo APxkVOCuHPewku2uspLRRjQGlqqB4nEP1Tq6+luhWLdNaPK61bMdo0f+QXMqqtbZ9aHoULB71IhL
echo ovsbltbd9L2flX1zVSnxlDeZieivT/zmjoW8KzvykztMhBBa8YvtL95788x5GYKtCGZalGDMs1q6
echo COWZvT2hwsN7TkBjRxdMcph0ydgS+viODqH6td1vF8Ghqxy+CdrwXh8N6fWe8325HVL85Ov7frd+
echo Lsc26VdPPZBRMXpV36HGHdTQvcqQvLGkOyonGhsn1wUfeR9zB35vzQOvqc2tTzsRVhx5ORWp7p5n
echo 4k0nViBRmMUfYuHM8VhyMMbMLbxSXZBVwCtF666Nv//luFlT5u3p6tWjqoE1ixKBYMC8G7NrUAQW
echo Y1DgUuDqYXmQKQD4y/KwYVJh5cxC/fY5F01rNYc//+GmxUa4IhfBK8GobmgfUCJdYpt3dbWICLk0
echo 3nh0iR6Pb3PkZFfIuilr7R0PcfAcO/dkymPqrrtXL058fGAV7opEM7KyNlofHelNNrbfaYc00ZPB
echo qIUsy2zhMXpdcL7+pZsev23a7KnffK+9zRjhVqR1dcdg7fuN0BxX07ZzRlPAbT2mGZCNGWQ7JFBN
echo CrGkKd00Nce47KIxV0tz1n/37eAMbnYIBOkjQDhnyJDxzm6pjWgNh29mR1vcHo9nPQr3NMcbDt7x
echo 3oo1q3h5zf2DmygLBoN2ZbXrnsBDALChKnCXzxQVuWF18OSg/zMGLNnHB53A3FfkXj1z8gPHqUoT
echo SZ0UuhWQMIJDsQQEdzdCvlO2vy8sL4Iyr8O+fUKmAllDM0GnAA4BQ1OfCs8d7yBXXZhD9x/MvL+n
echo 6tsvxmp/GQWEuM8hl0sUjn0nyKPN8YsfDmwxdx/YvGvjxsipMBpCyC7/TzcebGD+A2DVBh/r3rf6
echo oZPcUW0TUvsZMAoCNjGXZvm82beMqxztq+/qpQmT4mcaWkHECBRCwKIMmuIpeD8cg6hmDGoiH5kw
echo 3C3bJsVb3D+29kBLTMVRorGLK0rzY47yq2wclEkATFOO1aWHA4EAfn9lsPUUeBvjQL76JIHT8x8+
echo eEqf2+uzcxIiYg+jFkgknaMmjiqYr0uIRRIadokE3mqNwPF4yibB7V8zKfhH5MPEXK9tPpZlQVek
echo FzTGpU9gZ3svHI4mwSeL0JzQ2PChXuZzOq60z2IWHwjEGwB0GxS3jjMwDc6o/hmBQV2kGTKoSBdW
echo 1FS7mWWCQLABMMQ1JMc7qltL2SU93+AU+fw/DT5hWnBhrhduKC8EyiskAIh0d4NpGCARDH26Ce92
echo xkDivQcA/47dLoIyXPJo29+ohYDRzlPSH3Ch05jOarQYHNhkJVupkTJlTBjIU4c4nU5Hn24wO1oC
echo s4HakmYM3CKBRWOGAhkg1B+PQywaBUKIDThpWrYTp68DmJSBIAAoEs6xCWCKEbWO8s9VO//96PPf
echo bLArUHQiFAwz02jRQZLA7RANysCg9qVBkXAwukWhzOOAHCU9nEglkxDu6ACM08dwgj5ZgGxFhJRJ
echo gc+p+bO4U6N0ow7ESCHG6L5/B/wzEhicMFDG6HsWJk7oaY/2RONM5M3LqWpwYDHGoKVfBZUBpPr7
echo oa31pP2309fBlvw1ZbmQo4jgJAQWjS6E4R4XRDXTbi8RNVRqUXvUUpt3usT6/MPdcHo+RPXkm6ZA
echo ZIC3utrCt/RMBpzD8xVXAf+lWQzyXA6Y4HNApLMD1L4++3aeiU8t/lGnDEo9CiwbXwyGxWB4lpM+
echo X9eN+pP6Ib7HZLSVWam0BkKhfzkX/WwaqF1re73W37lDj4W7OJcjbZHdso6YrEiUIWyDqvAqsLo8
echo G67xMlD7YmD3jWeAHyTBe3CLgUIwOAUCScOCPSeiKJ5KvmETUJM7G+L72ga2s3PwfiAdc7v+9NOj
echo rUnvAQ7gWEvnbxsPnkSzsiWWiPSA2h2GfDUKuD8G4f4UWIBtgJ/6RARgUQCCgYXjJn6noTkGsZP2
echo pOPg7zfugtraU8XgOX5DUxu0KI/Hhz4M1bxZd3w8pWTJMA/1MBO2t/TAQ3ub4dGPWmDt7qPwdnvU
echo DpufNpflCS/TKZqv1kfx4eauTfDuL8J8vP6ffsXE0PwQRu2vJo8ca1u64fWj6JKhufR7Y4vZRble
echo EDHAWJ8Lpg7JtKMUD6//7C0cB5/hIObBLkPc/MbeY6n6xgd5zK8Nps31bNZZM+aT56/5a8iLofl/
echo 2KoEA+WFmcE7LxtKi9wy5eFdJIjPEu2QqVr0H/CbFmVeh2jGLUFc89t3oofqPp6Pjm2KMeBJ6+zf
echo F3/uF91VVQGhtjZouuY8fNfy6y760a0zz8eWnqQp3aIWZTyHIbusTh/CdcEEjJjHIQutcYA1L+w6
echo sO3F2m/ihqf2Ur+f8Ckc/LfX4PvdyrunLvrRy2/vfK+edXV0su6Odtbe0sxOnmiyfzpbW1iks5Od
echo aG5jz77yt9iUpc9uAMjy2vb7Bd4Rn5P/leAkXgzN5yNJKL32wRnfvXLivLElGVOy3UqxSJCT156q
echo ySIt3YlDtQc6tz/7yO+2Qu+WFp4G6ZrBCfb/ePn9hJ16DTu45mWWz/1Bod2wAyin/sqlXlNjT/LO
echo yX/K/D9lOMD3A9DyLQAAAABJRU5ErkJggg==) > "%B64I%"
certutil -decode "%B64I%" "%ICOPATH%" >nul 2>&1
del /q "%B64I%" >nul 2>&1
if not exist "%ICOPATH%" (echo         WARN: Icon creation failed) else (echo         OK: app.ico)

echo   [4/6] Registering file handler...

set "CUR="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /ve 2^>nul ^| find "REG_SZ"') do set "CUR=%%b"
if defined CUR (if not "%CUR%"=="%PROGID%" (reg add "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" /d "%CUR%" /f >nul 2>&1))

reg add "HKLM\SOFTWARE\Classes\%PROGID%" /ve /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%" /v "FriendlyTypeName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%\DefaultIcon" /ve /d "%ICOPATH%,0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%\shell\open\command" /ve /d "\"%BATPATH%\" \"%%1\"" /f >nul 2>&1

reg add "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat" /v "FriendlyAppName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat\DefaultIcon" /ve /d "%ICOPATH%,0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat\shell\open\command" /ve /d "\"%BATPATH%\" \"%%1\"" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat\SupportedTypes" /v ".pdf" /d "" /f >nul 2>&1

reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PROGID%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1
ftype %PROGID%="%BATPATH%" "%%1" >nul 2>&1
assoc .pdf=%PROGID% >nul 2>&1
echo         OK: Handler registered

echo   [5/6] Setting as default PDF app...
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities" /v "ApplicationName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities" /v "ApplicationDescription" /d "SIERA PDF - Upload and edit in ShareSuite" /f >nul 2>&1
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities" /v "ApplicationIcon" /d "%ICOPATH%,0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities\FileAssociations" /v ".pdf" /d "%PROGID%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "SieraPDF" /d "SOFTWARE\SieraPDF\Capabilities" /f >nul 2>&1

reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1
echo         OK: Default app registered

echo   Refreshing icon cache (Explorer will restart briefly)...
ie4uinit.exe -show >nul 2>&1
:: Delete icon cache files while Explorer is running (needs retry)
del /f /q "%LocalAppData%\IconCache.db" >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1
:: Kill Explorer and restart via scheduled task (runs as current user, not admin)
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 >nul
:: Delete cache files now that Explorer is not holding them
del /f /q "%LocalAppData%\IconCache.db" >nul 2>&1
del /f /q "%LocalAppData%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1
:: Restart Explorer as current interactive user (not admin)
powershell -NoProfile -Command "Start-Process explorer.exe" >nul 2>&1
:: Fallback: if still not running after 3 seconds, force start
timeout /t 3 >nul
tasklist /fi "imagename eq explorer.exe" | find /i "explorer.exe" >nul 2>&1
if errorlevel 1 start "" explorer.exe
timeout /t 2 >nul

echo   [6/6] Creating uninstaller...
>"%INSTDIR%\Uninstall.bat" (
echo @echo off
echo net session ^>nul 2^>^&1
echo if %%errorlevel%% neq 0 ^(powershell -Command "Start-Process '%%~f0' -Verb RunAs" ^& exit /b^)
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
echo taskkill /f /im explorer.exe ^>nul 2^>^&1
echo timeout /t 1 ^>nul
echo del /f /q "%%LocalAppData%%\IconCache.db" ^>nul 2^>^&1
echo del /f /q "%%LocalAppData%%\Microsoft\Windows\Explorer\iconcache*" ^>nul 2^>^&1
echo powershell -NoProfile -Command "Start-Process explorer.exe" ^>nul 2^>^&1
echo timeout /t 3 ^>nul
echo tasklist /fi "imagename eq explorer.exe" ^| find /i "explorer.exe" ^>nul 2^>^&1
echo if errorlevel 1 start "" explorer.exe
echo echo.
echo echo   SIERA PDF has been uninstalled.
echo echo.
echo pause
)
echo         OK: Uninstaller at %INSTDIR%\Uninstall.bat

echo.
echo   +==========================================================+
echo   ^|  SIERA PDF - Setup Complete!                             ^|
echo   ^|                                                          ^|
echo   ^|  Right-click any .pdf ^> Open with ^> SIERA PDF            ^|
echo   ^|  Or double-click if SIERA PDF is the default.            ^|
echo   ^|                                                          ^|
echo   ^|  Uninstall: %INSTDIR%\Uninstall.bat
echo   +==========================================================+

:done
echo.
pause
endlocal
