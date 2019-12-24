ItemsTable
==========

An example project, illustrating table filling and update.

Screen
------

![Screen](./images/Screen.gif)

Diagram
-------

<!--
            +------------ requests items ------------+
            |                                        |
            |                                        V
+-----------+-------------+              +-------------------------+
|   ItemsViewController   |              |  ItemsTableInteractor   |
+-----------+-------------+              +-----------+-------------+
            ^                                        |
            |                                        |
            +------------ sends new items -----------+
            |                                        |
            +----------- updates old items ----------+
-->

![Diagram](./images/Diagram.png)
