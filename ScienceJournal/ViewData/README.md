`ViewData/`
===
If your view is sufficiently complicated, you will want to populate it with an object meant to represent the view's state at that moment, instead of passing in a set of variables, you can pass a single object with properties.

The primary purpose is to help you become more protected from changes in the underlying data objects, and improving the overall testability of the project by not tightly coupling low-level data objects to views.
