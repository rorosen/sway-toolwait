use clap::{Args, Parser};
use std::{thread, time::Duration};
use swayipc::{Connection, Event, EventType, Fallible, WindowChange};

#[derive(Debug, Parser)]
struct Cli {
    #[command(flatten)]
    check: Check,

    /// Maximum time to wait for a new window
    #[arg(short, long, default_value_t = 5)]
    timeout: u64,

    /// Workspace to run command on
    #[arg(short = 's', long)]
    workspace: u32,

    /// Command to run
    #[arg(short, long)]
    command: String,
}

#[derive(Debug, Args)]
#[group(required = true, multiple = false)]
struct Check {
    /// app_id (wayland) or instance string (xwayland) to wait for
    #[arg(short, long)]
    waitfor: String,

    /// Stop waiting on any new window event (don't check app_id or instance string)
    #[arg(short, long)]
    nocheck: bool,
}

fn main() -> Fallible<()> {
    let cli = Cli::parse();

    thread::spawn(move || {
        thread::sleep(Duration::from_secs(cli.timeout));
        eprintln!("no matching new window event within timeout");
        std::process::exit(1);
    });

    let mut connection = Connection::new()?;
    let event_stream = Connection::new()?.subscribe([EventType::Window]);

    connection.run_command(format!("workspace {}", cli.workspace))?;
    connection.run_command(format!("exec {}", cli.command))?;

    for event in event_stream? {
        if let Ok(Event::Window(window_event)) = event {
            if cli.check.nocheck {
                std::process::exit(0);
            } else {
                if window_event.change == WindowChange::New {
                    if let Some(app_id) = window_event.container.app_id {
                        if app_id == cli.check.waitfor {
                            std::process::exit(0);
                        }
                    } else if let Some(properties) = window_event.container.window_properties {
                        if let Some(instance) = properties.instance {
                            if instance == cli.check.waitfor {
                                std::process::exit(0);
                            }
                        }
                    }
                }
            }
        }
    }
    Ok(())
}
