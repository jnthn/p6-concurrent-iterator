class Concurrent::Iterator does Iterator {
    has Mu $!target-iterator;
    has $!lock;
    has $!exception;

    method new(Iterable:D $target) {
        self.bless(:$target)
    }

    submethod TWEAK(:$target --> Nil) {
        $!target-iterator := $target.iterator;
        $!lock := Lock.new;
    }

    method pull-one() {
        $!lock.protect: {
            if $!target-iterator {
                my \pulled = $!target-iterator.pull-one;
                CATCH { $!exception := $_; $!target-iterator := Mu }
                $!target-iterator := Mu if pulled =:= IterationEnd;
                pulled
            }
            elsif $!exception {
                $!exception.rethrow
            }
            else {
                IterationEnd
            }
        }
    }
}

proto concurrent-iterator($) is export { * }
multi concurrent-iterator(Iterable:D \iterable) {
    Concurrent::Iterator.new(iterable)
}
multi concurrent-iterator($other) {
    concurrent-iterator($other.list)
}

sub concurrent-seq($target) is export {
    Seq.new(concurrent-iterator($target))
}
