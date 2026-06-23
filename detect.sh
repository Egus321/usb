#!/bin/sh
if command -v zenity >/dev/null 2>&1; then
    zenity --info --text="hi from usb"
elif command -v kdialog >/dev/null 2>&1; then
    kdialog --msgbox "hi from usb"
elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import tkinter as tk; from tkinter import messagebox; r=tk.Tk(); r.withdraw(); messagebox.showinfo('','hi from usb'); r.destroy()"
else
    notify-send "hi from usb"
fi
