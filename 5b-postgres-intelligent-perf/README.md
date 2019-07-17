# Azure Database for PostgreSQL 
Azure Database for PostgreSQL is a fully managed database service that is based on the open source version of PostgreSQL. The service offers built-in high availability, flexible scaling of compute and storage resources, and other features that enhance the existing engine functionality. 

In this hands-on lab, you will learn to use Intelligent Performance, a feature suite available in Azure Database for PostgreSQL that helps you understand and improve your workload's performance. The three features that make up the suite are Query Store, Query Performance Insight, and Performance Recommendations. 

## Prerequisites

If you are **not** at an event, please see [REQUIREMENTS](REQUIREMENTS.md) to install the prerequisites for this lab.

## Lab steps
1. Open the [Azure portal](https://portal.azure.com) in your browser. 

2. Use the search bar at the top of the screen to locate one of the following: `pgiperfdemo1` to `pgiperfdemo4`, which are [Azure Database for PostgreSQL](https://docs.microsoft.com/en-ca/azure/postgresql/) servers (if you are not at an event, your server name will be different).

3. Select **Query Performance Insight** from the menu on the left.

   The **Long running queries** tab appears and by default, lists the top 5 long running queries over the last 24 hours. 

4. Zoom in to a specific time window by clicking and dragging your cursor over the bar graph. This allows you to focus on the queries run in that period. 

5. View the table below the bar graph to learn more about the long running queries executed during that time period. The table shows the query text, duration of the query, number of times the query was executed, and the database it was run against. This data is sourced from Query Store.

6. Select the **Wait statistics** tab. (To find it, you may need to scroll back up in the window to see the tab. It is next to the **Long running queries** tab). By default, the page shows the top 5 wait events over the last 24 hours. 

   A wait event is a record of when a process in PostgreSQL was waiting for a resource. For example, a single query may need to wait for IO to be freed up in order to complete. This IO wait is then recorded in the Query Store as a wait event.

7. View the table below the graph to see the wait event types grouped by query. This gives you a comprehensive view of all the different types of wait events a query experienced. 

8. **Performance Recommendations** gives you suggestions on specific ways you can improve your workload performance. This feature currently supports create and drop index recommendations. These recommendations are customized to your database and are generated based on your specific workload.

   Select **Performance Recommendations** from the menu on the left.

9. View the recommendation(s) in the window. The table provides more information about the recommendation(s) and also the query text you can execute to create/drop the index. 
	

Congratulations! You have successfully gained insights into this server's query performance using the Intelligent Performance feature suite in Azure Database for PostgreSQL.

## Next steps
Learn more using the following resources: 
- Azure Database for PostgreSQL: [aka.ms/postgresql](https://aka.ms/postgresql) 
- Query Store: [aka.ms/postgresqlqs](https://aka.ms/postgresqlqs)
- Query Performance Insight: [aka.ms/postgresqlqpi](https://aka.ms/postgresqlqpi)
- Performance Recommendations: [aka.ms/postgresqlperfrec](https://aka.ms/postgresqlperfrec)

	
