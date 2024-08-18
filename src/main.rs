use clap::{Args, Parser};
use std::{process::ExitCode, sync::mpsc, thread, time::Duration};
use swayipc::{Connection, Event, EventType, WindowChange};

#[derive(Debug, Parser)]
struct Cli {
    /// Number of seconds to wait for a new matching window
    #[arg(short, long, default_value_t = 5)]
    timeout: u64,

    #[command(flatten)]
    sway: SwayArgs,
}

#[derive(Debug, Args)]
struct SwayArgs {
    /// Workspace to run command on
    #[arg(short = 's', long)]
    workspace: u32,

    /// Command to run
    #[arg(short, long)]
    command: String,

    /// app_id (wayland) or instance string (xwayland) to wait for
    #[arg(short, long)]
    waitfor: Option<String>,

    /// Additional arguments that are passed to the exec command
    #[arg(allow_hyphen_values = true, last = true)]
    pub extra_args: Vec<String>,
}

fn main() -> ExitCode {
    let cli = Cli::parse();
    let (tx, rx) = mpsc::channel();
    thread::spawn(move || tx.send(wait(&cli.sway)));

    match rx.recv_timeout(Duration::from_secs(cli.timeout)) {
        Ok(Ok(_)) => ExitCode::SUCCESS,
        Ok(Err(err)) => {
            eprintln!("Error waiting for matching new window: {err:#}");
            ExitCode::FAILURE
        }
        _ => {
            eprintln!("Timed out waiting for matching new window");
            ExitCode::FAILURE
        }
    }
}

fn wait(sway: &SwayArgs) -> Result<(), swayipc::Error> {
    let mut connection = Connection::new()?;
    let event_stream = Connection::new()?.subscribe([EventType::Window])?;
    connection.run_command(format!("workspace {}", sway.workspace))?;
    connection.run_command(format!(
        "exec {} {}",
        sway.command,
        sway.extra_args.join(" ")
    ))?;

    for event in event_stream {
        match event? {
            Event::Window(ev) if ev.change == WindowChange::New => {
                match &sway.waitfor {
                    Some(waitfor) => {
                        // TODO: chain once if-let-chains are stable https://github.com/rust-lang/rust/issues/53667
                        if let Some(app_id) = &ev.container.app_id {
                            if app_id == waitfor {
                                return Ok(());
                            }
                        }

                        if let Some(properties) = &ev.container.window_properties {
                            if let Some(instance) = &properties.instance {
                                if instance == waitfor {
                                    return Ok(());
                                }
                            }
                        }
                    }
                    None => return Ok(()),
                };
            }
            _ => (),
        }
    }

    panic!("Stopped to receive sway/i3 window events");
}
