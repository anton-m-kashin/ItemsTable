# ItemsTable

An example project, illustrating table filling and update.

---

``` ditaa

                +------- requests items --------+
                |                               |
                |                               V
    +-----------+-------------+    +--------------------------+
    |   ItemsViewController   |    |   ItemsTableInteractor   |
    +-----------+-------------+    +------------+-------------+
                ^                               |
                |                               |
                +------- sends new items -------+
                |                               |
                +------- updates old items -----+

```
