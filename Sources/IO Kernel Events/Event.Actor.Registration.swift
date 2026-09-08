#if !os(Windows)

    extension Event.Actor {

        struct Registration {
            var senders: Senders = Senders()
        }
    }

#endif
