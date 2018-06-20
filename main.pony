use "winApp"

actor Main
    new create(env: Env) =>
        let win = Window(WindowSettings.simple(80, 60, "Hello World"))
        
        try
            win.init() ?
        else
            env.out.print(win.getError())
        end