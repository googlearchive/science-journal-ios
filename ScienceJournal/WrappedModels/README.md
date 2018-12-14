`WrappedModels/`
===
Our data models are [protobufs](https://developers.google.com/protocol-buffers/). This is to decouple wire objects from presentation logic and in other places, models are wrapped to create a stable interface and insulate from any changes that might happen at low-level.
