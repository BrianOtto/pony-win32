use "winApp"

actor Main
    new create(env: Env) =>
        Window(WindowSettings.simple(80, 60, "Hello World"))