// Pas de console noire derrière la fenêtre en version release (Windows).
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    dsrp_launcher_lib::run()
}
