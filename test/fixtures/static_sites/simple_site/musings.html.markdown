# Designed to be flexible

The purpose of this static site generator is to make it _really easy_ to end up with a little blog. So, you don't even have to specify _any_ metadata. It should _just work_ right out of the box.

This file is used to assert:

- If given no metadata, or even a date in the filename, we use the file's `ctime` for the `occurred_at` date.
- We lop off the `markdown` or the `md` extensions, but only those. The url for this entry should be `/musings.html`
- Also, that simple file attachments "just work". Check out this cool image:

![you've changed](/youvechanged.jpg)
