import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';


const VolumeSlider = () => Widget.Slider({
    draw_value: false,
    hexpand: true,
    on_change: ({ value }) => Audio.speaker.volume = value,
}).hook(Audio, self => {
    if (!Audio.speaker)
      return;
    self.value = Audio.speaker.volume
  }, 'speaker-changed');

export default () => Widget.Box({
    children: [
        Widget.Button({
            child: Widget.Stack({
                children: {
                  '101': Widget.Icon('audio-volume-overamplified-symbolic'),
                  '67': Widget.Icon('audio-volume-high-symbolic'),
                  '34': Widget.Icon('audio-volume-medium-symbolic'),
                  '1':  Widget.Icon('audio-volume-low-symbolic'),
                  '0':  Widget.Icon('audio-volume-muted-symbolic'),
                },
                tooltipText: Audio.speaker.bind('volume')
                  .as(v => `Volume: ${Math.floor(v * 100)}%`),
              }).hook(Audio, stack => {
                if (!Audio.speaker)
                  return;
  
                if (Audio.speaker.isMuted) {
                  stack.shown = '0';
                  return;
                }
  
                const show = [101, 67, 34, 1, 0].find(
                  threshold => threshold <= Audio.speaker.volume * 100);
  
                stack.shown = `${show}`;
              }, 'speaker-changed'),
        }),
        VolumeSlider(),
    ],
});