# unsupported types abort cleanly

    Code
      as_syn_media(42L)
    Condition
      Error in `as_syn_media()`:
      ! Cannot coerce an integer to a <syn_media> object.
      i Supported sources: text, image (magick), audio (<Wave>), or a <prosody_score>.

# accessors validate their input

    Code
      media_type(list())
    Condition
      Error in `media_type()`:
      ! `x` must be a <syn_media> object, not an empty list.

# print.syn_media is stable

    Code
      print(as_syn_media("some text"))
    Message
      <syn_media> of type "text"

---

    Code
      print(as_syn_media(sc))
    Message
      <syn_media> of type "score"
      meta: "lang"

