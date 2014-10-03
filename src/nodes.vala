using Gee;
using Math;

namespace alaia {
    private float col_h2f(int col) {
        return (float)col/255;
    }
    private int rnd(float f) {
        int i = (int)f;
        float d = f - (float)i;
        if (d > 0.5f) 
            i++;
        return i;
    }

    class ConnectorConstraint : Clutter.Constraint {
        private Clutter.Actor source;
        private Clutter.Actor target;
        
        public ConnectorConstraint(Clutter.Actor source, Clutter.Actor target) {
            this.source=source;
            this.target=target;
        }
        
        public override void update_allocation(Clutter.Actor a, Clutter.ActorBox alloc) {
            stdout.printf("%f %f\n%f %f\n",this.source.x, this.source.width, this.source.y, this.source.height);
            alloc.x1 = this.source.x + this.source.width;
            alloc.y1 = this.source.y + this.source.height/2;
            alloc.x2 = this.target.x;
            a.height = (this.target.y+target.height/2-a.y)+2;
            (a.content as Clutter.Canvas).set_size(rnd(alloc.x2-alloc.x1), rnd(a.height));
            a.content.invalidate();
        }
    }
    
    class Connector : Clutter.Actor {
        private Clutter.Canvas c;
        private Node previous;
        private Node next;

        public Connector(Node previous, Node next) {
            this.previous = previous;
            this.next = next;
            this.c = new Clutter.Canvas();
            this.content = c;
            this.set_size(10,10);
            this.c.set_size(10,10);
            this.x = previous.x+previous.width;
            this.y = previous.y+previous.height;
            this.c.draw.connect(do_draw);
            this.add_constraint(
                new ConnectorConstraint(previous, next)
            );
            this.c.invalidate();
            this.previous.get_stage().add_child(this);
            
        }
        public bool do_draw(Cairo.Context cr, int w, int h) {
            stdout.printf("drawfoo connector %i %i\n", w,h);
            cr.set_source_rgba(0,0,0,1);
            cr.paint();
            cr.set_source_rgba(col_h2f(this.previous.color.red)*2,
                              col_h2f(this.previous.color.green)*2,
                              col_h2f(this.previous.color.blue)*2,
                              1);
            cr.set_source_rgba(1,1,1,1);
            cr.set_line_width(2.0);
            //cr.rel_curve_to(this.width,0,0,this.height,this.width,this.height);
            cr.line_to(w,h);
            cr.stroke();
            return true;
        } 
    }

    class NodeHighlight : Clutter.Actor {
        private Clutter.Canvas c;
        private Node parent;

        public NodeHighlight(Node parent) {
            this.parent = parent;
            this.c = new Clutter.Canvas();
            this.content = c;
            this.reactive=true;
            this.set_size(rnd(parent.width), rnd(parent.height));
            this.c.set_size(rnd(parent.width), rnd(parent.height));
            this.c.draw.connect(do_draw);
            this.add_constraint(
                new Clutter.BindConstraint(parent, Clutter.BindCoordinate.ALL,0)
            );
            this.c.invalidate();
        }


        public bool do_draw(Cairo.Context cr, int w, int h) {
            stdout.printf("drawing cairo shit\n");
            cr.set_source_rgba(0,0,0,0);
            cr.paint();
            cr.set_source_rgba(col_h2f(this.parent.color.red)*2,
                              col_h2f(this.parent.color.green)*2,
                              col_h2f(this.parent.color.blue)*2,
                              1);
            cr.set_line_width(5.0);
            cr.arc(38,38,33,0,2*Math.PI);
            cr.stroke();
            cr.set_source_rgba(col_h2f(this.parent.color.red),
                              col_h2f(this.parent.color.green),
                              col_h2f(this.parent.color.blue),
                              0.5);
            cr.arc(38,38,33,0,2*Math.PI);
            cr.fill();
            return true;
        }
    }
    class Node : Clutter.Rectangle {
        public static const uint8 COL_MULTIPLIER = 15;
        private Gee.ArrayList<Node> next;
        private Node? previous;
        private HistoryTrack track;
        private Clutter.Actor stage;
        private float xpos;
        private Gdk.Pixbuf favicon;
        private Gdk.Pixbuf snapshot;
        private Clutter.Actor favactor;
        private NodeHighlight highlight;

        private string _url;

        [Description(nick="url of this node", blurb="The url that this node represents")]
        public string url {
            get {
                return this._url;
            }
        }

        public Node(Clutter.Actor stage, HistoryTrack track, string url, Node? prv) {
            int y_offset = 37;
            this._url = url;
            this.previous = prv;
            this.next = new Gee.ArrayList<Node>();
            this.track = track;
            this.track.notify.connect(do_x_offset);
            this.stage = stage;
            this.xpos = 100;
            this.x = this.xpos;
            if (prv != null){
                stdout.printf("in here prvblock\n");
                this.x = this.xpos =prv.x;
                this.save_easing_state();
                this.x = this.xpos = prv.x+100;
                this.y = this.track.current_node.y;
                this.restore_easing_state();
                this.previous.next.add(this);
                y_offset += (this.first_node().get_splits())*100;
                new Connector(previous,this);
            }
            this.height = 75;
            this.width = 75;
            this.color = track.get_color().lighten();
            this.color = this.get_color().lighten();
            this.add_constraint(
                new Clutter.BindConstraint(track, Clutter.BindCoordinate.Y,y_offset)
            );
            this.reactive = true;
            this.motion_event.connect((x) => {return false;});

            this.favactor = new Clutter.Actor();
            this.favactor.height=this.favactor.width=24;
            this.favactor.add_constraint (
                new Clutter.BindConstraint(this, Clutter.BindCoordinate.POSITION, 26)
            );
            this.visible= false;
            this.highlight = new NodeHighlight(this);
            this.highlight.button_press_event.connect(do_button_press_event);
            stage.add_child(this);
            stage.add_child(this.highlight);
            stage.add_child(this.favactor);
            this.track.get_last_track().recalculate_y(0);
        }

        public void set_favicon(Gdk.Pixbuf px) {
            var img = new Clutter.Image();
            img.set_data(px.get_pixels(),
                           px.has_alpha ? Cogl.PixelFormat.RGBA_8888 : Cogl.PixelFormat.RGB_888,
                           px.width,
                           px.height,
                           px.rowstride);
            this.favactor.content = img;
        }

        public void do_x_offset(GLib.Object t, ParamSpec p) {
            if (p.name == "x-offset") {
                this.x = this.xpos + (t as HistoryTrack).x_offset;
            }
        }
        
        private bool do_button_press_event(Clutter.ButtonEvent e) {
            if (e.button == Gdk.BUTTON_PRIMARY) {
                this.track.current_node = this;
                this.track.load_page(this);
                return true;
            } else {
                return false;
            }
        }

        private Node first_node() {
            return this.previous == null ? this : this.previous.first_node();
        }

        public int get_splits() {
            int r = 0;
            foreach (Node n in this.next) {
                r += n.get_splits();
            }
            if (this.next.size > 1) {
                r += this.next.size - 1;
            }
            return r;
        }
    }
}
